import {
  Injectable,
  NotFoundException,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import * as nodemailer from 'nodemailer';
import { License_Status, Fine_Status } from '@prisma/client';

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

type LicenseUpdatePayload = {
  points: number;
  status: License_Status;
  suspended_Until: Date | null;
  has_24_Suspension?: boolean;
  has_50_Suspension?: boolean;
  has_100_Revoke?: boolean;
  triggering_Fine_Id?: string | null;
};

type FineWithPayment = {
  status: Fine_Status;
  issue_At: Date;
  payment: { amount: number } | null;
};

@Injectable()
export class FinesService {
  constructor(private prisma: PrismaService) {}

  @Cron('*/5 * * * *')
  async handleCron() {
    await this.processOverdueFines();
    await this.expireLicensesIfExpired();
  }

  private async expireLicensesIfExpired() {
    const licenses = await this.prisma.driving_License.findMany({
      where: {
        status: {
          notIn: ['EXPIRED', 'REVOKED'],
        },
      },
      include: {
        vehicleCategories: true,
      },
    });

    const now = new Date();
    const licensesToExpire: string[] = [];

    for (const license of licenses) {
      if (license.vehicleCategories.length === 0) {
        continue;
      }

      const maxExpiry = license.vehicleCategories.reduce(
        (max, cat) => (cat.expiry_Date > max ? cat.expiry_Date : max),
        license.vehicleCategories[0].expiry_Date,
      );

      if (maxExpiry < now) {
        licensesToExpire.push(license.license_Id);
      }
    }

    if (licensesToExpire.length > 0) {
      await this.prisma.driving_License.updateMany({
        where: {
          license_Id: { in: licensesToExpire },
        },
        data: {
          status: 'EXPIRED',
        },
      });
    }
  }

  private async sendWarningEmail(
    email: string,
    subject: string,
    message: string,
  ) {
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    await transporter.sendMail({
      from: `"Auto-Ledger" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: `⚠️ Auto-Ledger: ${subject}`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #1a1a2e; color: #ffffff; border-radius: 12px;">
          <h2 style="color: #ff6f00; text-align: center;">⚠️ License Status Update</h2>
          <p style="text-align: center; color: #cccccc;">${message}</p>
          <div style="background-color: #16213e; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <h3 style="color: #ff6f00;">${subject}</h3>
          </div>
          <p style="text-align: center; color: #aaaaaa;">Please login to the Auto-Ledger app for more details.</p>
          <hr style="border-color: #333;">
          <p style="text-align: center; color: #666666; font-size: 12px;">© 2026 Auto-Ledger</p>
        </div>
      `,
    });
  }

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
      await this.prisma.$transaction(async (tx) => {
        await tx.fine.update({
          where: { fine_Id: fine.fine_Id },
          data: { status: 'OVERDUE' },
        });

        await tx.driving_License.update({
          where: { license_Id: fine.license_Id },
          data: { status: 'SUSPENDED' },
        });

        await tx.temporary_License.deleteMany({
          where: { license_Id: fine.license_Id },
        });
      });
    }
  }

  async issueFine(data: {
    sessionId: string;
    officerId: string;
    offenseIds: string[];
    comment?: string;
  }) {
    const session = await this.prisma.qrSession.findUnique({
      where: { id: data.sessionId },
      include: { user: { include: { license: true } } },
    });

    if (!session || session.status !== 'ACTIVE') {
      throw new UnauthorizedException(
        'Scan session expired or invalid. Please scan QR again.',
      );
    }

    if (!session.user || !session.user.license) {
      throw new NotFoundException('License not found for this user.');
    }

    const licenseId = session.user.license.license_Id;

    await this.autoActivateLicenses();
    await this.processOverdueFines();
    await this.expireLicensesIfExpired();

    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { traffic_Officer_Id: data.officerId },
    });
    if (!officer) throw new NotFoundException('Officer not found');

    const currentHeadId = officer.divisional_Head_Id;

    const license = await this.prisma.driving_License.findUnique({
      where: { license_Id: licenseId },
    });
    if (!license) throw new NotFoundException('License not found');

    if (license.status === 'REVOKED' || license.status === 'EXPIRED') {
      throw new BadRequestException('License is revoked or expired.');
    }

    const offenses = await this.prisma.offence_Category.findMany({
      where: { offense_Id: { in: data.offenseIds } },
    });
    if (offenses.length === 0)
      throw new BadRequestException('No offenses found');

    const isCourtCase = offenses.some((o) => o.is_Court_Case);
    const fineDueDate = new Date();
    fineDueDate.setDate(fineDueDate.getDate() + 14);

    const oldPoints = license.points;
    const totalPointsAdded = offenses.reduce(
      (sum, off) => sum + off.points_Value,
      0,
    );
    const newPoints = oldPoints + totalPointsAdded;

    let newStatus: License_Status = license.status;
    let suspendedUntil = license.suspended_Until;
    let fineStatus: Fine_Status = 'PENDING';
    let isPointSuspension = false;
    let actionTriggered = false;
    let warningSubject = '';
    let warningMessage = '';

    if (!license.has_100_Revoke && newPoints >= 100) {
      newStatus = 'REVOKED';
      suspendedUntil = null;
      isPointSuspension = true;
      actionTriggered = true;
      warningSubject = 'License REVOKED (100 Points)';
      warningMessage =
        'Your license has been REVOKED due to exceeding 100 points. Please contact your Divisional Head.';
    } else if (
      !license.has_50_Suspension &&
      newPoints >= 50 &&
      !actionTriggered
    ) {
      newStatus = 'SUSPENDED';
      const now = new Date();
      suspendedUntil = new Date(now.setMonth(now.getMonth() + 6));
      isPointSuspension = true;
      actionTriggered = true;
      warningSubject = 'License SUSPENDED (6 Months)';
      warningMessage =
        'Your license has been SUSPENDED for 6 months due to exceeding 50 points.';
    } else if (
      !license.has_24_Suspension &&
      newPoints >= 24 &&
      !actionTriggered
    ) {
      newStatus = 'SUSPENDED';
      const now = new Date();
      suspendedUntil = new Date(now.setMonth(now.getMonth() + 1));
      isPointSuspension = true;
      actionTriggered = true;
      warningSubject = 'License SUSPENDED (1 Month)';
      warningMessage =
        'Your license has been SUSPENDED for 1 month due to exceeding 24 points.';
    }

    if (isCourtCase) {
      fineStatus = 'COURT_CASE';
      newStatus = 'SUSPENDED';
      if (!isPointSuspension) {
        suspendedUntil = null;
      }
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const fine = await tx.fine.create({
        data: {
          license_Id: licenseId,
          traffic_Officer_Id: data.officerId,
          head_Id: currentHeadId,
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

      const updateData: LicenseUpdatePayload = {
        points: newPoints,
        status: newStatus,
        suspended_Until: suspendedUntil,
      };

      if (actionTriggered && newPoints >= 24 && !license.has_24_Suspension) {
        updateData.has_24_Suspension = true;
      }
      if (actionTriggered && newPoints >= 50 && !license.has_50_Suspension) {
        updateData.has_50_Suspension = true;
      }
      if (actionTriggered && newPoints >= 100 && !license.has_100_Revoke) {
        updateData.has_100_Revoke = true;
        updateData.triggering_Fine_Id = fine.fine_Id;
      }

      await tx.driving_License.update({
        where: { license_Id: licenseId },
        data: updateData,
      });

      if (newStatus === 'SUSPENDED' || newStatus === 'REVOKED') {
        await tx.temporary_License.deleteMany({
          where: { license_Id: licenseId },
        });
      }

      let finalTempExpiry: Date | null = null;

      if (
        !isPointSuspension &&
        fineStatus !== 'COURT_CASE' &&
        newStatus !== 'REVOKED'
      ) {
        const existingTemp = await tx.temporary_License.findFirst({
          where: { license_Id: licenseId },
        });

        if (!existingTemp) {
          const createdTemp = await tx.temporary_License.create({
            data: {
              license_Id: licenseId,
              expiry_Date: fineDueDate,
              issued_By: data.officerId,
              head_Id: currentHeadId,
            },
          });
          finalTempExpiry = createdTemp.expiry_Date;
        } else {
          finalTempExpiry = existingTemp.expiry_Date;
        }

        if (newStatus !== 'SUSPENDED') {
          await tx.driving_License.update({
            where: { license_Id: licenseId },
            data: { status: 'TEMPORARY' },
          });
        }
      }

      const finalLicense = await tx.driving_License.findUnique({
        where: { license_Id: licenseId },
        select: { status: true },
      });

      if (actionTriggered && warningSubject) {
        const user = await tx.user.findUnique({
          where: { user_Id: license.user_Id },
        });
        if (user) {
          await this.sendWarningEmail(
            user.email,
            warningSubject,
            warningMessage,
          );
        }
      }

      return {
        fine: fine,
        licenseStatus: finalLicense?.status ?? newStatus,
        temporaryLicenseExpiry: finalTempExpiry,
      };
    });

    return result;
  }

  async getMyFines(userId: string) {
    await this.autoActivateLicenses();
    await this.processOverdueFines();
    await this.expireLicensesIfExpired();

    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: userId },
    });
    if (!license) throw new NotFoundException('License not found');

    const fines = await this.prisma.fine.findMany({
      where: { license_Id: license.license_Id },
      include: {
        offenses: { include: { offenceCategory: true } },
        trafficOfficer: { select: { name: true, badge_No: true } },
        payment: true,
      },
      orderBy: { issue_At: 'desc' },
    });

    return Promise.all(
      fines.map(async (fine) => {
        const scan = await this.prisma.qR_Scan_History.findFirst({
          where: {
            license_Id: fine.license_Id,
            traffic_Officer_Id: fine.traffic_Officer_Id,
            scan_Time: { lte: fine.issue_At },
          },
          orderBy: { scan_Time: 'desc' },
        });
        return {
          ...fine,
          scanLocation: scan?.location || null,
        };
      }),
    );
  }

  async payFine(fineId: string, amount: number) {
    const fine = await this.prisma.fine.findUnique({
      where: { fine_Id: fineId },
      include: { license: true, payment: true },
    });
    if (!fine) throw new NotFoundException('Fine not found');

    if (fine.status === 'PAID' || fine.payment)
      throw new BadRequestException('Fine already paid');

    const now = new Date();
    const isOverdue = fine.due_Date ? now > fine.due_Date : false;

    return this.prisma.$transaction(async (tx) => {
      await tx.payment.create({
        data: { fine_Id: fineId, amount: amount, status: 'COMPLETED' },
      });

      let newFineStatus: Fine_Status = 'PAID';
      if (isOverdue || fine.status === 'COURT_CASE') {
        newFineStatus = fine.status;
      }

      await tx.fine.update({
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

        if (pendingCount === 0 && currentLicense?.status !== 'REVOKED') {
          const isStillSuspended =
            currentLicense?.suspended_Until &&
            currentLicense.suspended_Until > now;

          let newLicenseStatus = currentLicense.status;
          if (!isStillSuspended) {
            newLicenseStatus = 'ACTIVE';
            await tx.temporary_License.deleteMany({
              where: { license_Id: fine.license_Id },
            });
          }

          await tx.driving_License.update({
            where: { license_Id: fine.license_Id },
            data: { status: newLicenseStatus },
          });
        }
      }

      return {
        message:
          isOverdue || fine.status === 'COURT_CASE'
            ? 'Payment recorded. Waiting for Divisional Head approval.'
            : 'Payment successful.',
        fineId: fineId,
      };
    });
  }

  async payBulkFines(fineIds: string[], totalAmount: number) {
    const fines = await this.prisma.fine.findMany({
      where: { fine_Id: { in: fineIds } },
      include: { license: true, payment: true },
    });
    if (fines.length !== fineIds.length)
      throw new BadRequestException('Invalid fines');

    for (const fine of fines) {
      if (fine.status === 'PAID' || fine.payment)
        throw new BadRequestException('One or more fines are already paid');
    }

    const licenseId = fines[0].license_Id;

    return this.prisma.$transaction(async (tx) => {
      let hasOverdueOrCourt = false;

      for (const fine of fines) {
        const now = new Date();
        const isOverdue = fine.due_Date ? now > fine.due_Date : false;
        if (isOverdue || fine.status === 'COURT_CASE') hasOverdueOrCourt = true;

        await tx.payment.create({
          data: {
            fine_Id: fine.fine_Id,
            amount: totalAmount / fineIds.length,
            status: 'COMPLETED',
          },
        });

        let newStatus: Fine_Status = 'PAID';
        if (isOverdue || fine.status === 'COURT_CASE') {
          newStatus = fine.status;
        }
        await tx.fine.update({
          where: { fine_Id: fine.fine_Id },
          data: { status: newStatus },
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

        if (pendingCount === 0 && currentLicense?.status !== 'REVOKED') {
          const now = new Date();
          const isStillSuspended =
            currentLicense?.suspended_Until &&
            currentLicense.suspended_Until > now;

          let newLicenseStatus = currentLicense.status;
          if (!isStillSuspended) {
            newLicenseStatus = 'ACTIVE';
            await tx.temporary_License.deleteMany({
              where: { license_Id: licenseId },
            });
          }

          await tx.driving_License.update({
            where: { license_Id: licenseId },
            data: { status: newLicenseStatus },
          });
        }
      }

      return { message: 'Bulk payment processed.' };
    });
  }

  async resolveOverdueCourtCase(
    fineId: string,
    verdict: 'ACTIVE' | 'REVOKED',
    headId: string,
  ) {
    const fine = await this.prisma.fine.findUnique({
      where: { fine_Id: fineId },
      include: {
        license: true,
        payment: true,
      },
    });
    if (!fine) throw new NotFoundException('Fine not found');

    if (fine.head_Id !== headId) {
      throw new UnauthorizedException(
        'This court case belongs to the previous Divisional Head.',
      );
    }

    if (fine.status !== 'OVERDUE' && fine.status !== 'COURT_CASE') {
      throw new BadRequestException('This fine is not overdue or court case.');
    }

    if (!fine.payment) {
      throw new BadRequestException(
        'Cannot make a decision: Fine is not paid yet.',
      );
    }

    if (verdict === 'ACTIVE') {
      const otherSeriousFines = await this.prisma.fine.count({
        where: {
          license_Id: fine.license_Id,
          status: { in: ['OVERDUE', 'COURT_CASE'] },
          fine_Id: { not: fineId },
        },
      });

      if (otherSeriousFines > 0) {
        throw new BadRequestException(
          'Cannot activate: There are other overdue or court case fines.',
        );
      }

      await this.prisma.$transaction(async (tx) => {
        await tx.fine.update({
          where: { fine_Id: fineId },
          data: { status: 'PAID' },
        });

        await tx.temporary_License.deleteMany({
          where: { license_Id: fine.license_Id },
        });

        const pendingFines = await tx.fine.findMany({
          where: {
            license_Id: fine.license_Id,
            status: 'PENDING',
          },
          orderBy: { issue_At: 'desc' },
        });

        if (pendingFines.length > 0) {
          const latestPending = pendingFines[0];
          await tx.temporary_License.create({
            data: {
              license_Id: fine.license_Id,
              expiry_Date:
                latestPending.due_Date ||
                new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
              issued_By: latestPending.traffic_Officer_Id,
              head_Id: latestPending.head_Id,
            },
          });

          await tx.driving_License.update({
            where: { license_Id: fine.license_Id },
            data: {
              status: 'TEMPORARY',
              suspended_Until: null,
            },
          });
        } else {
          await tx.driving_License.update({
            where: { license_Id: fine.license_Id },
            data: {
              status: 'ACTIVE',
              suspended_Until: null,
            },
          });
        }
      });

      return { message: 'License updated successfully.' };
    } else {
      await this.prisma.$transaction(async (tx) => {
        await tx.fine.update({
          where: { fine_Id: fineId },
          data: { status: 'PAID' },
        });

        await tx.driving_License.update({
          where: { license_Id: fine.license_Id },
          data: { status: 'REVOKED' },
        });
      });

      return { message: 'License revoked by Divisional Head.' };
    }
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
    if (!offense) throw new NotFoundException('Offense not found');

    return this.prisma.offence_Category.update({
      where: { offense_Id: id },
      data: { is_Active: !offense.is_Active },
    });
  }

  async getAllFinesForDMT() {
    await this.autoActivateLicenses();
    await this.expireLicensesIfExpired();
    const fines = await this.prisma.fine.findMany({
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

    return Promise.all(
      fines.map(async (fine) => {
        const scan = await this.prisma.qR_Scan_History.findFirst({
          where: {
            license_Id: fine.license_Id,
            traffic_Officer_Id: fine.traffic_Officer_Id,
            scan_Time: { lte: fine.issue_At },
          },
          orderBy: { scan_Time: 'desc' },
        });

        return {
          ...fine,
          scanLocation: scan?.location || null,
        };
      }),
    );
  }

  async getProblematicLicensesForDMT() {
    await this.autoActivateLicenses();
    await this.expireLicensesIfExpired();
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
    await this.expireLicensesIfExpired();

    const fines = await this.prisma.fine.findMany({
      where: {
        status: { in: ['OVERDUE', 'COURT_CASE'] },
        head_Id: headId,
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

    return Promise.all(
      fines.map(async (fine) => {
        const scan = await this.prisma.qR_Scan_History.findFirst({
          where: {
            license_Id: fine.license_Id,
            traffic_Officer_Id: fine.traffic_Officer_Id,
            scan_Time: { lte: fine.issue_At },
          },
          orderBy: { scan_Time: 'desc' },
        });

        return {
          ...fine,
          scanLocation: scan?.location || null,
        };
      }),
    );
  }

  async getDashboardStats(headId: string) {
    await this.autoActivateLicenses();
    await this.processOverdueFines();
    await this.expireLicensesIfExpired();

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

    const fines = await this.prisma.fine.findMany({
      where: { head_Id: headId },
      include: { payment: true },
    });

    const startOfDay = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
    );
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const calcRevenue = (fineArray: FineWithPayment[]) => {
      return fineArray
        .filter(
          (f): f is FineWithPayment & { payment: { amount: number } } =>
            f.status === 'PAID' && f.payment !== null,
        )
        .reduce((sum, f) => sum + f.payment.amount, 0);
    };

    const dailyFines = fines.filter((f) => new Date(f.issue_At) >= startOfDay);
    const monthlyFines = fines.filter(
      (f) => new Date(f.issue_At) >= startOfMonth,
    );

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
    const fines = await this.prisma.fine.findMany({
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

    return Promise.all(
      fines.map(async (fine) => {
        const scan = await this.prisma.qR_Scan_History.findFirst({
          where: {
            license_Id: fine.license_Id,
            traffic_Officer_Id: fine.traffic_Officer_Id,
            scan_Time: { lte: fine.issue_At },
          },
          orderBy: { scan_Time: 'desc' },
        });

        return {
          ...fine,
          scanLocation: scan?.location || null,
        };
      }),
    );
  }
}
