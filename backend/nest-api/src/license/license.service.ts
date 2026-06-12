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
  address: string;
  bloodGroup: string;
  dateOfBirth: string | Date;
  issueDate: string | Date;
  userId: string;
  dmtAdminId: string;
  image?: string;
  categories: VehicleCategoryData[];
}

@Injectable()
export class LicenseService {
  constructor(private prisma: PrismaService) {}

  async createLicense(data: CreateLicenseData) {
    let user = await this.prisma.user.findUnique({
      where: { nic_No: data.userId },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          nic_No: data.userId,
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
    });

    if (!license) throw new NotFoundException('Active license not found');
    if (license.status !== 'ACTIVE')
      throw new BadRequestException(`License is ${license.status}`);

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
}
