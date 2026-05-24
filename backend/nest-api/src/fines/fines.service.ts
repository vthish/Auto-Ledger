import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FinesService {
  constructor(private prisma: PrismaService) {}

  async issueFine(data: {
    licenseNumber: string;
    offenseCode: string;
    officerId: string;
  }) {
    const license = await this.prisma.license.findUnique({
      where: { licenseNumber: data.licenseNumber },
    });

    if (!license) {
      throw new NotFoundException('License not found in the system.');
    }

    if (license.status === 'REVOKED') {
      throw new BadRequestException(
        'This license is already permanently revoked.',
      );
    }

    const offense = await this.prisma.offenseCategory.findUnique({
      where: { code: data.offenseCode },
    });

    if (!offense) {
      throw new NotFoundException('Invalid offense code.');
    }

    const newPoints = license.points + offense.points;

    const tempExpiryDate = new Date();
    tempExpiryDate.setDate(tempExpiryDate.getDate() + 14);

    const result = await this.prisma.$transaction(async (prisma) => {
      const newFine = await prisma.fine.create({
        data: {
          dueDate: tempExpiryDate,
          status: 'PENDING',
          licenseId: license.id,
          officerId: data.officerId,
          offenseCategoryId: offense.id,
        },
      });

      const updatedLicense = await prisma.license.update({
        where: { id: license.id },
        data: {
          points: newPoints,
          status: 'SUSPENDED',
          temporaryLicenseExpiry: tempExpiryDate,
        },
      });

      return {
        fineDetails: newFine,
        licenseStatus: updatedLicense.status,
        accumulatedPoints: updatedLicense.points,
        temporaryLicenseExpiry: updatedLicense.temporaryLicenseExpiry,
      };
    });

    return result;
  }
}
