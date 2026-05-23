import { Injectable } from '@nestjs/common';
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
    return this.prisma.license.findUnique({
      where: { id },
      // Include the related user data so the frontend gets complete information
      include: {
        user: true,
      },
    });
  }
}
