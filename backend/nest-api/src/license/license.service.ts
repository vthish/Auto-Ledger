import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as crypto from 'crypto';

@Injectable()
export class LicenseService {
  constructor(private prisma: PrismaService) {}

  // 1. Create a License (DMT Admin)
  async createLicense(data: {
    licenseNo: string;
    issueDate: Date;
    expiryDate: Date;
    userId: string;
    dmtAdminId: string;
    image?: string;
  }) {
    return await this.prisma.driving_License.create({
      data: {
        license_No: data.licenseNo,
        issue_Date: data.issueDate,
        expiry_Date: data.expiryDate,
        user_Id: data.userId,
        dmt_Admin_Id: data.dmtAdminId,
        image: data.image,
      },
    });
  }

  // 2. Get User's Active License
  async getMyLicense(userId: string) {
    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: userId },
      include: {
        fines: { where: { status: 'PENDING' } },
        temporaryLicenses: true,
      },
    });
    if (!license) throw new NotFoundException('License not found');
    return license;
  }

  // 3. Generate 3-Minute QR Code (Driver Mobile App)
  async generateLicenseQR(userId: string) {
    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: userId },
    });

    if (!license) throw new NotFoundException('Active license not found');
    if (license.status !== 'ACTIVE')
      throw new BadRequestException(`License is ${license.status}`);

    // Generate a secure token and append expiration time (3 minutes from now)
    const expiryTime = Date.now() + 3 * 60 * 1000;
    const randomToken = crypto.randomBytes(16).toString('hex');
    const qrToken = `${license.license_Id}:${randomToken}:${expiryTime}`;

    return { qrToken, expiresAt: new Date(expiryTime) };
  }

  // 4. Scan QR & Save History (Traffic Officer App)
  async scanLicenseQR(
    qrToken: string,
    trafficOfficerId: string,
    location?: string,
  ) {
    const parts = qrToken.split(':');
    if (parts.length !== 3) throw new BadRequestException('Invalid QR format');

    const licenseId = parts[0];
    const expiryTime = parseInt(parts[2], 10);

    // Check if 3 minutes have passed
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

    // Save to QR_Scan_History
    await this.prisma.qR_Scan_History.create({
      data: {
        qr_Token: qrToken,
        traffic_Officer_Name: officer.name,
        driver_Name: license.user.name,
        location: location,
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

  // 5. Update License Status
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
