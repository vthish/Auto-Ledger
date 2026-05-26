import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { LicenseStatus, FineStatus } from '@prisma/client';

interface QrPayload {
  userId: string;
  nic: string;
  licenseNumber: string;
}

@Injectable()
export class FinesService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async issueFine(data: {
    qrToken: string;
    offenseCodes: string[];
    officerId: string;
  }) {
    let licenseNumber = '';

    try {
      const decoded: QrPayload = this.jwtService.verify(data.qrToken);
      licenseNumber = decoded.licenseNumber;
    } catch {
      throw new UnauthorizedException(
        'QR Token Expired or Invalid! Please scan the driver app again.',
      );
    }

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
      where: { licenseNumber },
    });

    if (!license) {
      throw new NotFoundException('License not found in the system.');
    }

    if (license.status === LicenseStatus.REVOKED) {
      throw new BadRequestException(
        'This license is already permanently revoked.',
      );
    }

    const offenses = await this.prisma.offenseCategory.findMany({
      where: { code: { in: data.offenseCodes } },
    });

    if (offenses.length === 0 || offenses.length !== data.offenseCodes.length) {
      throw new NotFoundException('One or more offense codes are invalid.');
    }

    const totalOffensePoints = offenses.reduce(
      (sum, off) => sum + off.points,
      0,
    );
    const newPoints = license.points + totalOffensePoints;

    const isCourtCase = offenses.some((off) => off.isCourtCase);

    const newLicenseStatus: LicenseStatus = isCourtCase
      ? LicenseStatus.COURT_PENDING
      : LicenseStatus.SUSPENDED;

    let tempExpiryDate: Date | null = null;
    if (!isCourtCase) {
      tempExpiryDate = new Date();
      tempExpiryDate.setDate(tempExpiryDate.getDate() + 14);
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const createdFines = await Promise.all(
        offenses.map((offense) => {
          const fineStatus = offense.isCourtCase
            ? FineStatus.COURT_CASE
            : FineStatus.PENDING;

          const fineDueDate = offense.isCourtCase ? null : tempExpiryDate;

          return tx.fine.create({
            data: {
              dueDate: fineDueDate,
              status: fineStatus,
              licenseId: license.id,
              officerId: data.officerId,
              offenseCategoryId: offense.id,
            },
            include: {
              offenseCategory: { select: { name: true, amount: true } },
            },
          });
        }),
      );

      const updatedLicense = await tx.license.update({
        where: { id: license.id },
        data: {
          points: newPoints,
          status: newLicenseStatus,
          temporaryLicenseExpiry: tempExpiryDate,
        },
      });

      return {
        fineDetails: createdFines,
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

  async getDriverFineHistory(userId: string) {
    const license = await this.prisma.license.findUnique({
      where: { userId },
    });

    if (!license) {
      throw new NotFoundException('No driving license found for this user.');
    }

    return this.prisma.fine.findMany({
      where: { licenseId: license.id },
      include: {
        offenseCategory: {
          select: { name: true, points: true, amount: true },
        },
        officer: { select: { badgeNumber: true } },
      },
      orderBy: { issuedAt: 'desc' },
    });
  }

  async calculateTotalAmount(fineIds: string[], userId: string) {
    if (!fineIds || fineIds.length === 0) {
      throw new BadRequestException('No fines selected.');
    }

    const fines = await this.prisma.fine.findMany({
      where: { id: { in: fineIds } },
      include: { license: true, offenseCategory: true },
    });

    if (fines.length === 0 || fines.some((f) => f.license.userId !== userId)) {
      throw new UnauthorizedException(
        'You do not have permission to view one or more of these fines.',
      );
    }

    if (fines.some((f) => f.status !== FineStatus.PENDING)) {
      throw new BadRequestException(
        'One or more selected fines cannot be paid.',
      );
    }

    const totalAmount = fines.reduce(
      (sum, fine) => sum + fine.offenseCategory.amount,
      0,
    );

    return { totalAmount };
  }

  async payFines(fineIds: string[], userId: string) {
    if (!fineIds || fineIds.length === 0) {
      throw new BadRequestException('No fines selected for payment.');
    }

    const fines = await this.prisma.fine.findMany({
      where: { id: { in: fineIds } },
      include: { license: true },
    });

    if (fines.length === 0 || fines.some((f) => f.license.userId !== userId)) {
      throw new UnauthorizedException(
        'You do not have permission to pay one or more of these fines.',
      );
    }

    if (fines.some((f) => f.status !== FineStatus.PENDING)) {
      throw new BadRequestException(
        'One or more fines cannot be paid. They may already be paid or are court cases.',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.fine.updateMany({
        where: { id: { in: fineIds } },
        data: { status: FineStatus.PAID },
      });

      const firstFine = fines[0];

      const otherPendingFinesCount = await tx.fine.count({
        where: {
          licenseId: firstFine.licenseId,
          status: FineStatus.PENDING,
        },
      });

      let updatedLicenseStatus: LicenseStatus = LicenseStatus.SUSPENDED;

      if (otherPendingFinesCount === 0) {
        await tx.license.update({
          where: { id: firstFine.licenseId },
          data: {
            status: LicenseStatus.ACTIVE,
            temporaryLicenseExpiry: null,
          },
        });
        updatedLicenseStatus = LicenseStatus.ACTIVE;
      }

      return {
        success: true,
        message: `Successfully paid ${fineIds.length} fine(s).`,
        licenseStatus: updatedLicenseStatus,
      };
    });
  }

  async getDistrictStatistics(districtId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const totalFinesToday = await this.prisma.fine.count({
      where: {
        officer: { districtId },
        issuedAt: { gte: today },
      },
    });

    const paidFines = await this.prisma.fine.findMany({
      where: {
        officer: { districtId },
        status: 'PAID',
        issuedAt: { gte: today },
      },
      include: { offenseCategory: true },
    });

    const revenueToday = paidFines.reduce(
      (sum, fine) => sum + fine.offenseCategory.amount,
      0,
    );

    const pendingCourtCases = await this.prisma.fine.count({
      where: {
        officer: { districtId },
        status: 'COURT_CASE',
      },
    });

    return {
      totalFinesToday,
      revenueToday,
      pendingCourtCases,
    };
  }
}
