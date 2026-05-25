import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { LicenseStatus, FineStatus } from '@prisma/client';

@Injectable()
export class FinesService {
  constructor(private prisma: PrismaService) {}

  async issueFine(data: {
    licenseNumber: string;
    offenseCode: string;
    officerId: string;
  }) {
    const officer = await this.prisma.officer.findUnique({
      where: { id: data.officerId },
      include: { shifts: { where: { isActive: true } } },
    });

    if (!officer) {
      throw new NotFoundException('Officer not found in the system.');
    }

    const activeShift = officer.shifts[0];

    if (activeShift) {
      const now = new Date();

      const currentTotalMinutes = now.getHours() * 60 + now.getMinutes();
      const shiftStartMinutes =
        activeShift.startTime.getHours() * 60 +
        activeShift.startTime.getMinutes();
      const shiftEndMinutes =
        activeShift.endTime.getHours() * 60 + activeShift.endTime.getMinutes();

      let isWithinShift = false;

      if (shiftStartMinutes <= shiftEndMinutes) {
        isWithinShift =
          currentTotalMinutes >= shiftStartMinutes &&
          currentTotalMinutes <= shiftEndMinutes;
      } else {
        isWithinShift =
          currentTotalMinutes >= shiftStartMinutes ||
          currentTotalMinutes <= shiftEndMinutes;
      }

      if (!isWithinShift) {
        throw new UnauthorizedException(
          'Access Denied: Officer is outside of active shift hours.',
        );
      }
    } else {
      throw new UnauthorizedException(
        'Access Denied: No active shift assigned to this officer.',
      );
    }

    const license = await this.prisma.license.findUnique({
      where: { licenseNumber: data.licenseNumber },
    });

    if (!license) {
      throw new NotFoundException('License not found in the system.');
    }

    if (license.status === LicenseStatus.REVOKED) {
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

    let newLicenseStatus: LicenseStatus = LicenseStatus.SUSPENDED;
    let newFineStatus: FineStatus = FineStatus.PENDING;
    let tempExpiryDate: Date | null = null;

    if (offense.isCourtCase) {
      newLicenseStatus = LicenseStatus.COURT_PENDING;
      newFineStatus = FineStatus.COURT_CASE;
    } else {
      tempExpiryDate = new Date();
      tempExpiryDate.setDate(tempExpiryDate.getDate() + 14);
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const newFine = await tx.fine.create({
        data: {
          dueDate: tempExpiryDate,
          status: newFineStatus,
          licenseId: license.id,
          officerId: data.officerId,
          offenseCategoryId: offense.id,
        },
      });

      const updatedLicense = await tx.license.update({
        where: { id: license.id },
        data: {
          points: newPoints,
          status: newLicenseStatus,
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

  async resolveCourtCase(fineId: string, finalVerdict: 'ACTIVE' | 'REVOKED') {
    const fine = await this.prisma.fine.findUnique({
      where: { id: fineId },
      include: { license: true },
    });

    if (!fine || fine.status !== FineStatus.COURT_CASE) {
      throw new NotFoundException('Valid pending court case not found.');
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.fine.update({
        where: { id: fineId },
        data: { status: FineStatus.RESOLVED },
      });

      return tx.license.update({
        where: { id: fine.licenseId },
        data: {
          status:
            finalVerdict === 'ACTIVE'
              ? LicenseStatus.ACTIVE
              : LicenseStatus.REVOKED,
          points: finalVerdict === 'ACTIVE' ? 0 : fine.license.points,
          temporaryLicenseExpiry: null,
        },
      });
    });
  }

  async getCourtCasesByDistrict(districtId: string) {
    return this.prisma.fine.findMany({
      where: {
        status: FineStatus.COURT_CASE,
        officer: { districtId: districtId },
      },
      include: {
        officer: { select: { badgeNumber: true, name: true } },
        offenseCategory: true,
        license: { select: { licenseNumber: true } },
      },
      orderBy: { issuedAt: 'desc' },
    });
  }

  async getOffenses() {
    return this.prisma.offenseCategory.findMany();
  }

  async verifyLicense(licenseNumber: string) {
    const license = await this.prisma.license.findUnique({
      where: { licenseNumber },
      include: {
        fines: {
          orderBy: { issuedAt: 'desc' },
          take: 3,
          include: { offenseCategory: true },
        },
      },
    });

    if (!license) {
      throw new NotFoundException('License not found in the system.');
    }

    return license;
  }

  async getOfficerFineHistory(officerId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return this.prisma.fine.findMany({
      where: {
        officerId: officerId,
        issuedAt: { gte: today },
      },
      include: {
        license: { select: { licenseNumber: true } },
        offenseCategory: { select: { name: true, points: true } },
      },
      orderBy: { issuedAt: 'desc' },
    });
  }
}
