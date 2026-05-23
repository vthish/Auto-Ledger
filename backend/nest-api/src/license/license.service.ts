import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class LicenseService {
  constructor(private prisma: PrismaService) {}

  // Issue a new driving license to a specific user
  async issueLicense(data: {
    licenseNumber: string;
    expiryDate: string;
    userId: string;
  }) {
    return this.prisma.license.create({
      data: {
        licenseNumber: data.licenseNumber,
        // Convert the incoming date string to a valid Date object for Prisma
        expiryDate: new Date(data.expiryDate),
        userId: data.userId,
      },
    });
  }

  // Retrieve license details using the license ID, including driver details
  async getLicenseById(id: string) {
    const license = await this.prisma.license.findUnique({
      where: { id },
      // Include the related user data so the frontend gets complete information
      include: {
        user: true,
      },
    });

    // If the license does not exist in the database, throw a 404 error
    if (!license) {
      throw new NotFoundException('License not found in the system');
    }

    return license;
  }

  // Update license details (e.g., add violation points, extend expiry date)
  async updateLicense(
    id: string,
    data: { expiryDate?: string; points?: number },
  ) {
    // Replaced 'any' with a strict TypeScript type to fix ESLint errors
    const updateData: { points?: number; expiryDate?: Date } = {
      points: data.points,
    };

    if (data.expiryDate) {
      updateData.expiryDate = new Date(data.expiryDate);
    }

    return this.prisma.license.update({
      where: { id },
      data: updateData,
    });
  }

  // Revoke or delete a license from the system
  async deleteLicense(id: string) {
    return this.prisma.license.delete({
      where: { id },
    });
  }
}
