import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { isAxiosError } from 'axios';

// Define the exact structure of the data coming from the Mock DMT API
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

@Injectable()
export class LicenseService {
  constructor(
    private prisma: PrismaService,
    private httpService: HttpService,
  ) {}

  // Issue a new license automatically via DMT integration using NIC
  async issueLicense(data: { nic: string; userId: string }) {
    const dmtApiUrl =
      process.env.DMT_API_URL || 'http://localhost:4000/api/dmt/license';

    try {
      // 1. Fetch data and explicitly tell TypeScript it will match DmtApiResponse
      const response = await firstValueFrom(
        this.httpService.get<DmtApiResponse>(`${dmtApiUrl}/${data.nic}`),
      );

      const dmtData = response.data.data;

      // 2. Save the newly fetched license details
      return await this.prisma.license.create({
        data: {
          licenseNumber: dmtData.licenseNumber,
          // Safely access the expiryDate since the type is now known
          expiryDate: new Date(dmtData.vehicleCategories[0].expiryDate),
          userId: data.userId,
        },
      });
    } catch (error: unknown) {
      // Safely check if the error is an Axios error before accessing .response
      if (isAxiosError(error)) {
        if (error.response?.status === 404) {
          throw new NotFoundException(
            'DMT Error: No driving license found for this NIC number.',
          );
        }
      }

      throw new BadRequestException(
        'System Error: Could not connect to DMT Server.',
      );
    }
  }

  // Retrieve license details using the license ID, including driver details
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

  // Update license details
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

  // Revoke or delete a license from the system
  async deleteLicense(id: string) {
    return this.prisma.license.delete({ where: { id } });
  }
}
