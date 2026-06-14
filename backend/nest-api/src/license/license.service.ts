import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as crypto from 'crypto';

export interface VehicleCategoryData {
  vehicleClass: string;
  issueDate: string | Date;
  expiryDate: string | Date;
  restriction?: string;
}

export interface CreateLicenseData {
  licenseNo: string;
  fullName: string;
  nicNo: string;
  address: string;
  bloodGroup: string;
  dateOfBirth: string | Date;
  issueDate: string | Date;
  dmtAdminId: string;
  image?: string;
  categories: VehicleCategoryData[];
}

export interface UpdateLicenseData {
  fullName?: string;
  address?: string;
  bloodGroup?: string;
  image?: string;
  dateOfBirth?: string | Date;
  issueDate?: string | Date;
  categories?: VehicleCategoryData[];
}

@Injectable()
export class LicenseService {
  constructor(private prisma: PrismaService) {}

  async createLicense(data: CreateLicenseData) {
    let user = await this.prisma.user.findUnique({
      where: { nic_No: data.nicNo },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          nic_No: data.nicNo,
          name: 'Pending App Registration',
          password: 'NOT_REGISTERED',
          mobile_Phone_No: 'PENDING',
          device_Id: 'PENDING',
        },
      });
    }

    return await this.prisma.driving_License.create({
      data: {
        license_No: data.licenseNo,
        full_Name: data.fullName,
        nic_No: data.nicNo,
        address: data.address,
        blood_Group: data.bloodGroup,
        date_of_birth: new Date(data.dateOfBirth),
        issue_Date: new Date(data.issueDate),
        user_Id: user.user_Id,
        dmt_Admin_Id: data.dmtAdminId,
        image: data.image,
        vehicleCategories: {
          create: data.categories.map((cat) => ({
            vehicle_Class: cat.vehicleClass,
            issue_Date: new Date(cat.issueDate),
            expiry_Date: new Date(cat.expiryDate),
            restriction: cat.restriction || null,
          })),
        },
      },
      include: {
        vehicleCategories: true,
      },
    });
  }

  async getMyLicense(userId: string) {
    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: userId },
      include: {
        fines: { where: { status: 'PENDING' } },
        temporaryLicenses: true,
        vehicleCategories: true,
      },
    });
    if (!license) throw new NotFoundException('License not found');
    return license;
  }

  async generateLicenseQR(userId: string) {
    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: userId },
      include: {
        temporaryLicenses: true,
        fines: { where: { status: 'PENDING' } },
      },
    });

    if (!license) throw new NotFoundException('Active license not found');

    if (license.status === 'REVOKED' || license.status === 'EXPIRED') {
      throw new BadRequestException(`License is ${license.status}`);
    }

    if (license.status === 'SUSPENDED') {
      if (license.temporaryLicenses.length > 0) {
        const tempLicense = license.temporaryLicenses[0];
        const now = new Date();

        if (now > new Date(tempLicense.expiry_Date)) {
          for (const fine of license.fines) {
            await this.prisma.fine.update({
              where: { fine_Id: fine.fine_Id },
              data: { status: 'OVERDUE' },
            });
          }
          throw new BadRequestException(
            'Temporary license has expired. Auto-escalated to Court Case. QR Code generation blocked.',
          );
        }
      } else {
        throw new BadRequestException(
          'License is suspended. QR Code generation blocked.',
        );
      }
    }

    const expiryTime = Date.now() + 3 * 60 * 1000;
    const randomToken = crypto.randomBytes(16).toString('hex');
    const qrToken = `${license.license_Id}:${randomToken}:${expiryTime}`;

    return { qrToken, expiresAt: new Date(expiryTime) };
  }

  async scanLicenseQR(
    qrToken: string,
    trafficOfficerId: string,
    location?: string,
  ) {
    const parts = qrToken.split(':');
    if (parts.length !== 3) throw new BadRequestException('Invalid QR format');

    const licenseId = parts[0];
    const expiryTime = parseInt(parts[2], 10);

    if (Date.now() > expiryTime) {
      throw new BadRequestException(
        'QR Code has expired. Please ask driver to refresh.',
      );
    }

    const license = await this.prisma.driving_License.findUnique({
      where: { license_Id: licenseId },
      include: { user: true },
    });

    if (!license) throw new NotFoundException('License not found');

    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { traffic_Officer_Id: trafficOfficerId },
    });

    if (!officer) throw new UnauthorizedException('Invalid Officer');

    await this.prisma.qR_Scan_History.create({
      data: {
        qr_Token: qrToken,
        traffic_Officer_Name: officer.name,
        driver_Name: license.user.name,
        location: location || null,
        license_Id: license.license_Id,
      },
    });

    return {
      message: 'Scan successful',
      driverName: license.user.name,
      licenseNo: license.license_No,
      status: license.status,
      points: license.points,
    };
  }

  async updateStatus(
    licenseId: string,
    newStatus: 'ACTIVE' | 'SUSPENDED' | 'EXPIRED' | 'REVOKED',
  ) {
    return this.prisma.driving_License.update({
      where: { license_Id: licenseId },
      data: { status: newStatus },
    });
  }

  async getLicenseByNIC(nicNo: string) {
    const license = await this.prisma.driving_License.findUnique({
      where: { nic_No: nicNo },
      include: {
        vehicleCategories: true,
        fines: {
          include: {
            offenses: { include: { offenceCategory: true } },
            payment: true,
          },
          orderBy: { issue_At: 'desc' },
        },
      },
    });

    if (!license) throw new NotFoundException('License not found for this NIC');
    return license;
  }

  async getAllLicenses(nic?: string) {
    return this.prisma.driving_License.findMany({
      where: nic ? { nic_No: { contains: nic, mode: 'insensitive' } } : {},
      include: {
        vehicleCategories: true,
      },
      orderBy: { issue_Date: 'desc' },
    });
  }

  async updateLicenseDetails(licenseId: string, data: UpdateLicenseData) {
    const license = await this.prisma.driving_License.findUnique({
      where: { license_Id: licenseId },
    });

    if (!license) throw new NotFoundException('License not found');

    const updatePayload: {
      full_Name?: string;
      address?: string;
      blood_Group?: string;
      image?: string;
      date_of_birth?: Date;
      issue_Date?: Date;
      vehicleCategories?: any;
    } = {};

    if (data.fullName) updatePayload.full_Name = data.fullName;
    if (data.address) updatePayload.address = data.address;
    if (data.bloodGroup) updatePayload.blood_Group = data.bloodGroup;
    if (data.image) updatePayload.image = data.image;
    if (data.dateOfBirth)
      updatePayload.date_of_birth = new Date(data.dateOfBirth);
    if (data.issueDate) updatePayload.issue_Date = new Date(data.issueDate);

    if (data.categories && data.categories.length > 0) {
      await this.prisma.license_Vehicle_Category.deleteMany({
        where: { license_Id: licenseId },
      });
      updatePayload.vehicleCategories = {
        create: data.categories.map((cat) => ({
          vehicle_Class: cat.vehicleClass,
          issue_Date: new Date(cat.issueDate),
          expiry_Date: new Date(cat.expiryDate),
          restriction: cat.restriction || null,
        })),
      };
    }

    return this.prisma.driving_License.update({
      where: { license_Id: licenseId },
      data: updatePayload,
      include: { vehicleCategories: true },
    });
  }

  async getLicensesWithFines(nic?: string) {
    return this.prisma.driving_License.findMany({
      where: {
        fines: { some: {} },
        ...(nic ? { nic_No: { contains: nic, mode: 'insensitive' } } : {}),
      },
      include: {
        fines: {
          include: {
            offenses: { include: { offenceCategory: true } },
            trafficOfficer: { select: { name: true, badge_No: true } },
          },
          orderBy: { issue_At: 'desc' },
        },
      },
    });
  }
}
