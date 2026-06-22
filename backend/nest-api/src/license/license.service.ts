import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { JwtService } from '@nestjs/jwt';

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
  private s3Client: S3Client;

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
    private jwtService: JwtService,
  ) {
    const region =
      this.configService.get<string>('AWS_REGION') || 'ap-southeast-1';
    const accessKeyId =
      this.configService.get<string>('AWS_ACCESS_KEY_ID') || '';
    const secretAccessKey =
      this.configService.get<string>('AWS_SECRET_ACCESS_KEY') || '';

    this.s3Client = new S3Client({
      region: region,
      credentials: {
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey,
      },
    });
  }

  private async autoActivateLicenses() {
    await this.prisma.driving_License.updateMany({
      where: { status: 'SUSPENDED', suspended_Until: { lte: new Date() } },
      data: { suspended_Until: null },
    });

    const licensesToActivate = await this.prisma.driving_License.findMany({
      where: {
        status: 'SUSPENDED',
        suspended_Until: null,
        fines: {
          none: { status: { in: ['PENDING', 'OVERDUE', 'COURT_CASE'] } },
        },
      },
    });

    if (licensesToActivate.length > 0) {
      await this.prisma.driving_License.updateMany({
        where: {
          license_Id: { in: licensesToActivate.map((l) => l.license_Id) },
        },
        data: { status: 'ACTIVE', points: 0 },
      });
    }
  }

  async getS3UploadUrl(fileName: string, fileType: string) {
    const bucketName =
      this.configService.get<string>('AWS_S3_BUCKET_NAME') ||
      'auto-ledger-images';
    const region = process.env.AWS_REGION || 'ap-southeast-1';

    const cleanFileName = fileName.replace(/\s+/g, '-');
    const uniqueFileName = `licenses/${Date.now()}-${cleanFileName}`;

    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: uniqueFileName,
      ContentType: fileType,
    });

    const uploadUrl = await getSignedUrl(this.s3Client, command, {
      expiresIn: 60,
    });
    const publicFileUrl = `https://${bucketName}.s3.${region}.amazonaws.com/${uniqueFileName}`;
    return {
      uploadUrl,
      fileUrl: publicFileUrl,
    };
  }

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
          mobile_Phone_No: `PENDING_${data.nicNo}`,
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
    await this.autoActivateLicenses();
    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: userId },
      include: {
        fines: {
          where: { status: { in: ['PENDING', 'OVERDUE', 'COURT_CASE'] } },
        },
        temporaryLicenses: true,
        vehicleCategories: true,
      },
    });
    if (!license) throw new NotFoundException();
    return license;
  }

  async generateLicenseQR(userId: string) {
    await this.autoActivateLicenses();
    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: userId },
      include: {
        temporaryLicenses: true,
        fines: {
          where: { status: { in: ['PENDING', 'OVERDUE', 'COURT_CASE'] } },
        },
      },
    });

    if (!license) throw new NotFoundException();

    if (license.status === 'REVOKED' || license.status === 'EXPIRED') {
      throw new BadRequestException();
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
          await this.prisma.temporary_License.deleteMany({
            where: { license_Id: license.license_Id },
          });
          throw new BadRequestException();
        }
      } else {
        throw new BadRequestException();
      }
    }

    const randomToken = crypto.randomBytes(16).toString('hex');
    const qrToken = `${license.license_Id}:${randomToken}`;

    return { qrToken };
  }

  async checkScanStatus(qrToken: string) {
    if (!qrToken) throw new BadRequestException();

    const scan = await this.prisma.qR_Scan_History.findFirst({
      where: { qr_Token: qrToken },
    });

    return { scanned: !!scan };
  }

  async scanLicenseQR(
    qrToken: string,
    trafficOfficerId: string,
    location?: string,
  ) {
    const parts = qrToken.split(':');
    if (parts.length !== 2) throw new BadRequestException();

    const licenseId = parts[0];

    await this.autoActivateLicenses();
    const license = await this.prisma.driving_License.findUnique({
      where: { license_Id: licenseId },
      include: { user: true },
    });

    if (!license) throw new NotFoundException();

    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { traffic_Officer_Id: trafficOfficerId },
    });

    if (!officer) throw new UnauthorizedException();

    await this.prisma.qR_Scan_History.create({
      data: {
        qr_Token: qrToken,
        traffic_Officer_Id: trafficOfficerId,
        traffic_Officer_Name: officer.name,
        driver_Name: license.user.name,
        location: location || null,
        license_Id: license.license_Id,
      },
    });

    const scanToken = this.jwtService.sign(
      { licenseId: license.license_Id },
      { expiresIn: '3m' },
    );

    return {
      driverName: license.user.name,
      licenseNo: license.license_No,
      status: license.status,
      points: license.points,
      scanToken: scanToken,
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
    await this.autoActivateLicenses();
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

    if (!license) throw new NotFoundException();
    return license;
  }

  async getAllLicenses(nic?: string) {
    await this.autoActivateLicenses();
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

    if (!license) throw new NotFoundException();

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
    await this.autoActivateLicenses();
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
