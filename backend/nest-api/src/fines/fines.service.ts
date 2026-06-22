import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { Fine, Payment } from '@prisma/client';

export interface CreateOffenseData {
  code: string;
  name: string;
  points: number;
  amount: number;
  isCourtCase: boolean;
}

export interface UpdateOffenseData {
  name?: string;
  points?: number;
  amount?: number;
  isCourtCase?: boolean;
}

type FineWithPayment = Fine & { payment: Payment | null };

interface ScanTokenPayload {
  licenseId: string;
  iat?: number;
  exp?: number;
}

@Injectable()
export class FinesService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  private async autoActivateLicenses() {
    await this.prisma.driving_License.updateMany({
      where: { status: 'SUSPENDED', suspended_Until: { lte: new Date() } },
      data: { status: 'ACTIVE', suspended_Until: null },
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

  private async processOverdueFines() {
    const overdueFines = await this.prisma.fine.findMany({
      where: { status: 'PENDING', due_Date: { lt: new Date() } },
    });

    for (const fine of overdueFines) {
      await this.prisma.fine.update({
        where: { fine_Id: fine.fine_Id },
        data: { status: 'OVERDUE' },
      });

      await this.prisma.temporary_License.deleteMany({
        where: { license_Id: fine.license_Id },
      });
    }
  }

  async issueFine(data: {
    scanToken: string;
    officerId: string;
    offenseIds: string[];
    comment?: string;
  }) {
    let licenseId = '';
    try {
      const payload = this.jwtService.verify<ScanTokenPayload>(data.scanToken);
      licenseId = payload.licenseId;
    } catch {
      throw new UnauthorizedException(
        'Scan session expired. Please scan QR again.',
      );
    }

    await this.autoActivateLicenses();
    await this.processOverdueFines();

    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { traffic_Officer_Id: data.officerId },
    });
    if (!officer) throw new NotFoundException();

    const license = await this.prisma.driving_License.findUnique({
      where: { license_Id: licenseId },
    });
    if (!license) throw new NotFoundException();

    const offenses = await this.prisma.offence_Category.findMany({
      where: { offense_Id: { in: data.offenseIds } },
    });
    if (offenses.length === 0) throw new BadRequestException();

    const isCourtCase = offenses.some((o) => o.is_Court_Case);
    const fineDueDate = new Date();
    fineDueDate.setDate(fineDueDate.getDate() + 14);

    const oldPoints = license.points;
    const totalPointsAdded = offenses.reduce(
      (sum, off) => sum + off.points_Value,
      0,
    );
    const newPoints = oldPoints + totalPointsAdded;

    let newStatus = license.status as 'ACTIVE' | 'SUSPENDED' | 'REVOKED';
    if (newStatus !== 'REVOKED' && newStatus !== 'SUSPENDED') {
      newStatus = 'ACTIVE';
    }

    let suspendedUntil = license.suspended_Until;
    let fineStatus: 'PENDING' | 'COURT_CASE' = 'PENDING';
    let isPointSuspension = false;

    const now = new Date();

    if (newPoints >= 100 && oldPoints < 100) {
      newStatus = 'REVOKED';
      suspendedUntil = null;
      isPointSuspension = true;
    } else if (newPoints >= 50 && oldPoints < 50) {
      newStatus = 'SUSPENDED';
      suspendedUntil = new Date(now.setMonth(now.getMonth() + 6));
      isPointSuspension = true;
    } else if (newPoints >= 24 && oldPoints < 24) {
      newStatus = 'SUSPENDED';
      suspendedUntil = new Date(now.setMonth(now.getMonth() + 1));
      isPointSuspension = true;
    } else if (isCourtCase) {
      newStatus = 'SUSPENDED';
      fineStatus = 'COURT_CASE';
    } else if (oldPoints >= 100 || license.status === 'REVOKED') {
      newStatus = 'REVOKED';
    }

    return this.prisma.$transaction(async (tx) => {
      const fine = await tx.fine.create({
        data: {
          license_Id: licenseId,
          traffic_Officer_Id: data.officerId,
          due_Date: fineDueDate,
          status: fineStatus,
          comment: data.comment || null,
        },
      });

      for (const offense of offenses) {
        await tx.fine_Offence.create({
          data: { fine_Id: fine.fine_Id, offense_Id: offense.offense_Id },
        });
      }

      await tx.driving_License.update({
        where: { license_Id: licenseId },
        data: {
          points: newPoints,
          status: newStatus,
          suspended_Until: suspendedUntil,
        },
      });

      if (!isPointSuspension && !isCourtCase && newStatus !== 'REVOKED') {
        const existingTemp = await tx.temporary_License.findFirst({
          where: { license_Id: licenseId },
        });

        if (!existingTemp) {
          await tx.temporary_License.create({
            data: {
              license_Id: licenseId,
              expiry_Date: fineDueDate,
              issued_By: data.officerId,
            },
          });
        }
      }

      return fine;
    });
  }

  async getMyFines(userId: string) {
    await this.autoActivateLicenses();
    await this.processOverdueFines();

    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: userId },
    });
    if (!license) throw new NotFoundException();

    return this.prisma.fine.findMany({
      where: { license_Id: license.license_Id },
      include: {
        offenses: { include: { offenceCategory: true } },
        trafficOfficer: { select: { name: true, badge_No: true } },
        payment: true,
      },
      orderBy: { issue_At: 'desc' },
    });
  }

  async payFine(fineId: string, amount: number) {
    const fine = await this.prisma.fine.findUnique({
      where: { fine_Id: fineId },
      include: { license: true },
    });
    if (!fine) throw new NotFoundException();
    if (fine.status === 'PAID') throw new BadRequestException();

    const now = new Date();
    const isOverdue = fine.due_Date ? now > fine.due_Date : false;

    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.create({
        data: { fine_Id: fineId, amount: amount, status: 'COMPLETED' },
      });

      const newFineStatus =
        isOverdue || fine.status === 'COURT_CASE' ? fine.status : 'PAID';

      const updatedFine = await tx.fine.update({
        where: { fine_Id: fineId },
        data: { status: newFineStatus },
      });

      if (!isOverdue && fine.status !== 'COURT_CASE') {
        const pendingCount = await tx.fine.count({
          where: {
            license_Id: fine.license_Id,
            status: { in: ['PENDING', 'OVERDUE', 'COURT_CASE'] },
            fine_Id: { not: fineId },
          },
        });

        const currentLicense = await tx.driving_License.findUnique({
          where: { license_Id: fine.license_Id },
        });

        const isPointsSuspended = currentLicense?.suspended_Until != null;

        if (
          pendingCount === 0 &&
          currentLicense?.status !== 'REVOKED' &&
          !isPointsSuspended
        ) {
          await tx.temporary_License.deleteMany({
            where: { license_Id: fine.license_Id },
          });
          await tx.driving_License.update({
            where: { license_Id: fine.license_Id },
            data: { status: 'ACTIVE' },
          });
        }
      }

      return {
        message:
          isOverdue || fine.status === 'COURT_CASE'
            ? 'Payment recorded. Waiting for Divisional Head approval.'
            : 'Payment successful. License activated.',
        paymentId: payment.payment_Id,
        fineStatus: updatedFine.status,
      };
    });
  }

  async payBulkFines(fineIds: string[], totalAmount: number) {
    const fines = await this.prisma.fine.findMany({
      where: { fine_Id: { in: fineIds } },
      include: { license: true },
    });
    if (fines.length !== fineIds.length) throw new BadRequestException();

    for (const fine of fines) {
      if (fine.status === 'PAID') throw new BadRequestException();
    }

    const licenseId = fines[0].license_Id;

    return this.prisma.$transaction(async (tx) => {
      const payments: { payment_Id: string }[] = [];
      let hasOverdueOrCourt = false;

      for (const fine of fines) {
        const now = new Date();
        const isOverdue = fine.due_Date ? now > fine.due_Date : false;

        if (isOverdue || fine.status === 'COURT_CASE') {
          hasOverdueOrCourt = true;
        }

        const p = await tx.payment.create({
          data: {
            fine_Id: fine.fine_Id,
            amount: totalAmount / fineIds.length,
            status: 'COMPLETED',
          },
        });
        payments.push(p);

        const newFineStatus =
          isOverdue || fine.status === 'COURT_CASE' ? fine.status : 'PAID';

        await tx.fine.update({
          where: { fine_Id: fine.fine_Id },
          data: { status: newFineStatus },
        });
      }

      if (!hasOverdueOrCourt) {
        const pendingCount = await tx.fine.count({
          where: {
            license_Id: licenseId,
            status: { in: ['PENDING', 'OVERDUE', 'COURT_CASE'] },
            fine_Id: { notIn: fineIds },
          },
        });

        const currentLicense = await tx.driving_License.findUnique({
          where: { license_Id: licenseId },
        });

        const isPointsSuspended = currentLicense?.suspended_Until != null;

        if (
          pendingCount === 0 &&
          currentLicense?.status !== 'REVOKED' &&
          !isPointsSuspended
        ) {
          await tx.temporary_License.deleteMany({
            where: { license_Id: licenseId },
          });
          await tx.driving_License.update({
            where: { license_Id: licenseId },
            data: { status: 'ACTIVE' },
          });
        }
      }

      return {
        message: hasOverdueOrCourt
          ? 'Payment recorded. Waiting for Divisional Head approval.'
          : 'Bulk payment successful.',
        payments: payments.map((p) => p.payment_Id),
      };
    });
  }

  async updateCourtCase(fineId: string, verdict: 'ACTIVE' | 'REVOKED') {
    const fine = await this.prisma.fine.findUnique({
      where: { fine_Id: fineId },
      include: { license: true },
    });
    if (!fine) throw new NotFoundException();

    return this.prisma.$transaction(async (tx) => {
      await tx.fine.update({
        where: { fine_Id: fineId },
        data: { status: 'PAID' },
      });

      return tx.driving_License.update({
        where: { license_Id: fine.license_Id },
        data: {
          status: verdict,
          points: verdict === 'ACTIVE' ? 0 : fine.license.points,
          suspended_Until: null,
        },
      });
    });
  }

  async getAllOffenses() {
    return this.prisma.offence_Category.findMany({ orderBy: { code: 'asc' } });
  }

  async createOffenseCategory(data: CreateOffenseData, policeAdminId: string) {
    return this.prisma.offence_Category.create({
      data: {
        code: data.code,
        name: data.name,
        amount: data.amount,
        points_Value: data.points,
        is_Court_Case: data.isCourtCase,
        police_Admin_Id: policeAdminId,
      },
    });
  }

  async updateOffenseCategory(id: string, data: UpdateOffenseData) {
    return this.prisma.offence_Category.update({
      where: { offense_Id: id },
      data: {
        name: data.name,
        points_Value: data.points,
        amount: data.amount,
        is_Court_Case: data.isCourtCase,
      },
    });
  }

  async toggleOffenseStatus(id: string) {
    const offense = await this.prisma.offence_Category.findUnique({
      where: { offense_Id: id },
    });
    if (!offense) throw new NotFoundException();

    return this.prisma.offence_Category.update({
      where: { offense_Id: id },
      data: { is_Active: !offense.is_Active },
    });
  }

  async getAllFinesForDMT() {
    await this.autoActivateLicenses();
    return this.prisma.fine.findMany({
      include: {
        license: {
          select: { license_No: true, nic_No: true, full_Name: true },
        },
        offenses: {
          include: { offenceCategory: true },
        },
      },
      orderBy: { issue_At: 'desc' },
    });
  }

  async getProblematicLicensesForDMT() {
    await this.autoActivateLicenses();
    return this.prisma.driving_License.findMany({
      where: {
        status: { in: ['SUSPENDED', 'REVOKED'] },
      },
      orderBy: { points: 'desc' },
    });
  }

  async getCourtCasesByDH(headId: string) {
    await this.autoActivateLicenses();
    await this.processOverdueFines();

    const officers = await this.prisma.traffic_Officer.findMany({
      where: { divisional_Head_Id: headId },
      select: { traffic_Officer_Id: true },
    });
    const officerIds = officers.map((o) => o.traffic_Officer_Id);

    return this.prisma.fine.findMany({
      where: {
        status: { in: ['OVERDUE', 'COURT_CASE'] },
        traffic_Officer_Id: { in: officerIds },
      },
      include: {
        license: {
          select: { license_No: true, full_Name: true, nic_No: true },
        },
        trafficOfficer: { select: { name: true, badge_No: true } },
        offenses: { include: { offenceCategory: true } },
        payment: true,
      },
      orderBy: { issue_At: 'desc' },
    });
  }

  async getDashboardStats(headId: string) {
    await this.autoActivateLicenses();
    await this.processOverdueFines();

    const now = new Date();
    const officers = await this.prisma.traffic_Officer.findMany({
      where: { divisional_Head_Id: headId },
      include: {
        shifts: {
          where: {
            start_Time: { lte: now },
            end_Time: { gte: now },
            is_Active: true,
          },
        },
      },
    });

    const officerIds = officers.map((o) => o.traffic_Officer_Id);

    const fines = await this.prisma.fine.findMany({
      where: { traffic_Officer_Id: { in: officerIds } },
      include: { payment: true },
    });

    const startOfDay = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
    );
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const dailyFines = fines.filter((f) => new Date(f.issue_At) >= startOfDay);
    const monthlyFines = fines.filter(
      (f) => new Date(f.issue_At) >= startOfMonth,
    );

    const calcRevenue = (fineArray: FineWithPayment[]) =>
      fineArray
        .filter((f) => f.status === 'PAID' && f.payment)
        .reduce((sum, f) => sum + (f.payment?.amount || 0), 0);

    return {
      totalOfficers: officers.length,
      activeOfficersOnDuty: officers.filter((o) => o.shifts.length > 0).length,
      totalFinesIssued: fines.length,
      pendingFinesCount: fines.filter((f) => f.status === 'PENDING').length,
      overdueCourtCases: fines.filter(
        (f) => f.status === 'OVERDUE' || f.status === 'COURT_CASE',
      ).length,
      totalRevenue: calcRevenue(fines),
      daily: { count: dailyFines.length, revenue: calcRevenue(dailyFines) },
      monthly: {
        count: monthlyFines.length,
        revenue: calcRevenue(monthlyFines),
      },
    };
  }

  async getTrafficOfficerStats(officerId: string) {
    const now = new Date();
    const startOfDay = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
    );
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const fines = await this.prisma.fine.findMany({
      where: { traffic_Officer_Id: officerId },
      include: { payment: true },
    });

    const qrScans = await this.prisma.qR_Scan_History.count({
      where: { traffic_Officer_Id: officerId },
    });

    const tempLicenses = await this.prisma.temporary_License.count({
      where: { issued_By: officerId },
    });

    const stats = {
      daily: { count: 0, revenue: 0 },
      monthly: { count: 0, revenue: 0 },
      allTime: {
        count: 0,
        revenue: 0,
        qrScans: qrScans,
        tempLicenses: tempLicenses,
      },
    };

    fines.forEach((f) => {
      const issueDate = new Date(f.issue_At);
      const isPaid = f.status === 'PAID' && f.payment;
      const amount = isPaid ? f.payment.amount : 0;

      stats.allTime.count++;
      stats.allTime.revenue += amount;

      if (issueDate >= startOfMonth) {
        stats.monthly.count++;
        stats.monthly.revenue += amount;
      }
      if (issueDate >= startOfDay) {
        stats.daily.count++;
        stats.daily.revenue += amount;
      }
    });

    return stats;
  }

  async getOfficerFines(officerId: string) {
    return this.prisma.fine.findMany({
      where: { traffic_Officer_Id: officerId },
      include: {
        license: {
          select: { license_No: true, full_Name: true, nic_No: true },
        },
        offenses: { include: { offenceCategory: true } },
        payment: true,
      },
      orderBy: { issue_At: 'desc' },
    });
  }
}
