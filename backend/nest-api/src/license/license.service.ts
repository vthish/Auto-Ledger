import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { HttpService } from '@nestjs/axios';
import { JwtService } from '@nestjs/jwt';
import { firstValueFrom } from 'rxjs';
import { isAxiosError } from 'axios';

interface DmtApiResponse {
  success: boolean;
  data: {
    licenseNumber: string;
    fullName: string;
    address: string;
    dob: string;
    bloodGroup: string;
    dateOfIssue: string;
    vehicleCategories: Array<{
      class: string;
      issueDate: string;
      expiryDate: string;
    }>;
  };
}

interface QrPayload {
  userId: string;
  nic: string;
  licenseNumber: string;
}

@Injectable()
export class LicenseService {
  constructor(
    private prisma: PrismaService,
    private httpService: HttpService,
    private jwtService: JwtService,
  ) {}

  async issueLicense(data: { nic: string; userId: string }) {
    const dmtApiUrl =
      process.env.DMT_API_URL || 'http://localhost:4000/api/dmt/license';

    try {
      const response = await firstValueFrom(
        this.httpService.get<DmtApiResponse>(`${dmtApiUrl}/${data.nic}`),
      );

      const dmtData = response.data.data;

      return await this.prisma.license.create({
        data: {
          licenseNumber: dmtData.licenseNumber,
          expiryDate: new Date(dmtData.vehicleCategories[0].expiryDate),
          userId: data.userId,
        },
      });
    } catch (error: unknown) {
      if (isAxiosError(error) && error.response?.status === 404) {
        throw new NotFoundException(
          'DMT Error: No driving license found for this NIC number.',
        );
      }
      throw new BadRequestException(
        'System Error: Could not connect to DMT Server.',
      );
    }
  }

  async getVirtualCardDetails(userId: string) {
    const license = await this.prisma.license.findUnique({
      where: { userId },
      include: { user: true },
    });

    if (!license) {
      throw new NotFoundException('License record not found in local system.');
    }

    const dmtApiUrl =
      process.env.DMT_API_URL || 'http://localhost:4000/api/dmt/license';

    try {
      const response = await firstValueFrom(
        this.httpService.get<DmtApiResponse>(
          `${dmtApiUrl}/${license.user.nic}`,
        ),
      );

      const dmtData = response.data.data;

      const qrPayload: QrPayload = {
        userId: license.userId,
        nic: license.user.nic,
        licenseNumber: license.licenseNumber,
      };

      const qrToken = this.jwtService.sign(qrPayload, { expiresIn: '1m' });

      return {
        licenseNumber: license.licenseNumber,
        status: license.status,
        points: license.points,
        temporaryLicenseExpiry: license.temporaryLicenseExpiry,
        fullName: dmtData.fullName,
        address: dmtData.address,
        dob: dmtData.dob,
        bloodGroup: dmtData.bloodGroup,
        vehicleCategories: dmtData.vehicleCategories,
        qrToken: qrToken,
      };
    } catch (error: unknown) {
      if (isAxiosError(error) && error.response?.status === 404) {
        throw new NotFoundException(
          'DMT Error: Legal license details not found.',
        );
      }
      throw new BadRequestException(
        'System Error: Unable to fetch data from DMT.',
      );
    }
  }

  async getLicenseByQrToken(token: string) {
    try {
      const decoded: QrPayload = this.jwtService.verify(token);
      const userId = decoded.userId;

      const license = await this.prisma.license.findUnique({
        where: { userId },
        include: { user: true },
      });

      if (!license) {
        throw new NotFoundException('License not found.');
      }

      const dmtApiUrl =
        process.env.DMT_API_URL || 'http://localhost:4000/api/dmt/license';
      const response = await firstValueFrom(
        this.httpService.get<DmtApiResponse>(
          `${dmtApiUrl}/${license.user.nic}`,
        ),
      );

      const dmtData = response.data.data;

      return {
        licenseNumber: license.licenseNumber,
        status: license.status,
        points: license.points,
        temporaryLicenseExpiry: license.temporaryLicenseExpiry,
        fullName: dmtData.fullName,
        address: dmtData.address,
        dob: dmtData.dob,
        bloodGroup: dmtData.bloodGroup,
        vehicleCategories: dmtData.vehicleCategories,
      };
    } catch {
      throw new UnauthorizedException(
        'QR Code has expired or is invalid. Please scan again.',
      );
    }
  }

  async getLicenseById(id: string) {
    const license = await this.prisma.license.findUnique({
      where: { id },
      include: { user: true },
    });

    if (!license) {
      throw new NotFoundException('License not found in the system');
    }
    return license;
  }

  async updateLicense(
    id: string,
    data: { expiryDate?: string; points?: number },
  ) {
    const updateData: { points?: number; expiryDate?: Date } = {
      points: data.points,
    };

    if (data.expiryDate) {
      updateData.expiryDate = new Date(data.expiryDate);
    }

    return this.prisma.license.update({ where: { id }, data: updateData });
  }

  async deleteLicense(id: string) {
    return this.prisma.license.delete({ where: { id } });
  }
}
