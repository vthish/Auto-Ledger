import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Prisma } from '@prisma/client';

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

interface MulterFile {
  buffer: Buffer;
  originalname: string;
  mimetype: string;
}

type LicenseStatusUpdate = 'ACTIVE' | 'SUSPENDED' | 'EXPIRED' | 'REVOKED';

interface UpdatePayload extends Prisma.Driving_LicenseUpdateInput {
  full_Name?: string;
  address?: string;
  blood_Group?: string;
  image?: string;
  date_of_birth?: Date;
  issue_Date?: Date;
  status?: LicenseStatusUpdate;
  vehicleCategories?: {
    deleteMany: Record<string, never>;
    create: Array<{
      vehicle_Class: string;
      issue_Date: Date;
      expiry_Date: Date;
      restriction: string | null;
    }>;
  };
}

@Injectable()
export class LicenseService {
  private s3Client: S3Client;

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
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

  private validateNic(nicNo: string): string {
    const normalizedNic = nicNo.trim();
    const nicRegex = /^(?:\d{9}[VvXx]|\d{12})$/;

    if (!nicRegex.test(normalizedNic)) {
      throw new BadRequestException(
        'NIC must contain 9 digits followed by V/X or exactly 12 digits.',
      );
    }

    return normalizedNic;
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
        data: { status: 'ACTIVE' },
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

  async uploadImageToS3(file: MulterFile) {
    const bucketName =
      this.configService.get<string>('AWS_S3_BUCKET_NAME') ||
      'auto-ledger-images-handling';
    const region = process.env.AWS_REGION || 'ap-southeast-1';

    const cleanFileName = file.originalname.replace(/\s+/g, '-');
    const uniqueFileName = `licenses/${Date.now()}-${cleanFileName}`;

    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: uniqueFileName,
      Body: file.buffer,
      ContentType: file.mimetype,
    });

    await this.s3Client.send(command);

    const publicFileUrl = `https://${bucketName}.s3.${region}.amazonaws.com/${uniqueFileName}`;
    return {
      fileUrl: publicFileUrl,
      message: 'Image uploaded successfully',
    };
  }

  async createLicense(data: CreateLicenseData) {
    const nicNo = this.validateNic(data.nicNo);

    let user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user) {
      user = await this.prisma.user.create({
        data: {
          nic_No: nicNo,
          name: 'Pending App Registration',
          password: 'NOT_REGISTERED',
          email: `pending_${nicNo}@example.com`,
          device_Id: 'PENDING',
        },
      });
    }

    return await this.prisma.driving_License.create({
      data: {
        license_No: data.licenseNo,
        full_Name: data.fullName,
        nic_No: nicNo,
        address: data.address,
        blood_Group: data.bloodGroup,
        date_of_birth: new Date(data.dateOfBirth),
        issue_Date: new Date(data.issueDate),
        user_Id: user.user_Id,
        dmt_Admin_Id: data.dmtAdminId,
        image: data.image,
        has_24_Suspension: false,
        has_50_Suspension: false,
        has_100_Revoke: false,
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
    if (!license) throw new NotFoundException('License not found');
    return license;
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

    if (!license) throw new NotFoundException('License not found');
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
      include: {
        fines: {
          where: {
            status: { in: ['PENDING', 'OVERDUE', 'COURT_CASE'] },
          },
        },
      },
    });

    if (!license) throw new NotFoundException('License not found');

    if (!data.categories || data.categories.length === 0) {
      const updatePayload: UpdatePayload = {};
      if (data.fullName) updatePayload.full_Name = data.fullName;
      if (data.address) updatePayload.address = data.address;
      if (data.bloodGroup) updatePayload.blood_Group = data.bloodGroup;
      if (data.image) updatePayload.image = data.image;
      if (data.dateOfBirth)
        updatePayload.date_of_birth = new Date(data.dateOfBirth);
      if (data.issueDate) updatePayload.issue_Date = new Date(data.issueDate);
      return this.prisma.driving_License.update({
        where: { license_Id: licenseId },
        data: updatePayload,
        include: { vehicleCategories: true },
      });
    }

    const now = new Date();
    const newMaxExpiry = data.categories.reduce(
      (max, cat) =>
        new Date(cat.expiryDate) > max ? new Date(cat.expiryDate) : max,
      new Date(data.categories[0].expiryDate),
    );

    let newStatus: LicenseStatusUpdate = license.status as LicenseStatusUpdate;

    if (license.status === 'REVOKED') {
      newStatus = 'REVOKED';
    } else {
      const hasUnresolvedFines = license.fines.length > 0;

      if (newMaxExpiry >= now) {
        if (hasUnresolvedFines) {
          newStatus = 'SUSPENDED';
        } else {
          newStatus = 'ACTIVE';
        }
      } else {
        newStatus = 'EXPIRED';
      }
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.license_Vehicle_Category.deleteMany({
        where: { license_Id: licenseId },
      });

      const updatePayload: UpdatePayload = {
        status: newStatus,
        vehicleCategories: {
          deleteMany: {},
          create: data.categories.map((cat) => ({
            vehicle_Class: cat.vehicleClass,
            issue_Date: new Date(cat.issueDate),
            expiry_Date: new Date(cat.expiryDate),
            restriction: cat.restriction || null,
          })),
        },
      };

      if (data.fullName) updatePayload.full_Name = data.fullName;
      if (data.address) updatePayload.address = data.address;
      if (data.bloodGroup) updatePayload.blood_Group = data.bloodGroup;
      if (data.image) updatePayload.image = data.image;
      if (data.dateOfBirth)
        updatePayload.date_of_birth = new Date(data.dateOfBirth);
      if (data.issueDate) updatePayload.issue_Date = new Date(data.issueDate);

      const updatedLicense = await tx.driving_License.update({
        where: { license_Id: licenseId },
        data: updatePayload,
        include: { vehicleCategories: true },
      });

      return updatedLicense;
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

  async getRevokedLicenses(headId: string) {
    await this.autoActivateLicenses();
    return this.prisma.driving_License.findMany({
      where: {
        status: 'REVOKED',
        triggering_Fine: {
          head_Id: headId,
        },
      },
      include: {
        user: {
          select: { name: true, email: true },
        },
        triggering_Fine: {
          include: {
            offenses: { include: { offenceCategory: true } },
            trafficOfficer: { select: { name: true, badge_No: true } },
          },
        },
      },
      orderBy: { issue_Date: 'desc' },
    });
  }

  async resolveRevokedLicense(
    licenseId: string,
    verdict: 'ACTIVE' | 'REVOKED',
    headId: string,
  ) {
    const license = await this.prisma.driving_License.findUnique({
      where: { license_Id: licenseId },
      include: {
        triggering_Fine: true,
      },
    });
    if (!license) throw new NotFoundException('License not found');
    if (license.status !== 'REVOKED') {
      throw new BadRequestException('License is not in REVOKED status');
    }

    if (license.triggering_Fine && license.triggering_Fine.head_Id !== headId) {
      throw new UnauthorizedException(
        'This revocation belongs to the previous Divisional Head.',
      );
    }

    if (verdict === 'ACTIVE') {
      const pendingFines = await this.prisma.fine.count({
        where: {
          license_Id: licenseId,
          status: { in: ['PENDING', 'OVERDUE', 'COURT_CASE'] },
        },
      });

      if (pendingFines > 0) {
        throw new BadRequestException(
          'Cannot activate: There are pending/overdue/court case fines.',
        );
      }

      return this.prisma.driving_License.update({
        where: { license_Id: licenseId },
        data: {
          status: 'ACTIVE',
          points: 0,
          suspended_Until: null,
          has_24_Suspension: false,
          has_50_Suspension: false,
          has_100_Revoke: false,
          triggering_Fine_Id: null,
        },
      });
    } else {
      return this.prisma.driving_License.update({
        where: { license_Id: licenseId },
        data: { status: 'REVOKED' },
      });
    }
  }
}
