import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

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

@Injectable()
export class FinesService {
  constructor(private prisma: PrismaService) {}

  async issueFine(data: {
    licenseId: string;
    officerId: string;
    offenseIds: string[];
    comment?: string;
  }) {
    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { traffic_Officer_Id: data.officerId },
    });
    if (!officer) throw new NotFoundException('Officer not found');

    const license = await this.prisma.driving_License.findUnique({
      where: { license_Id: data.licenseId },
    });
    if (!license) throw new NotFoundException('License not found');

    const offenses = await this.prisma.offence_Category.findMany({
      where: { offense_Id: { in: data.offenseIds } },
    });
    if (offenses.length === 0)
      throw new BadRequestException('Invalid offenses');

    const isCourtCase = offenses.some((o) => o.is_Court_Case);
    const fineDueDate = new Date();
    fineDueDate.setDate(fineDueDate.getDate() + 14);

    return this.prisma.$transaction(async (tx) => {
      const fine = await tx.fine.create({
        data: {
          license_Id: data.licenseId,
          traffic_Officer_Id: data.officerId,
          due_Date: fineDueDate,
          status: 'PENDING',
          comment: data.comment || null,
        },
      });

      for (const offense of offenses) {
        await tx.fine_Offence.create({
          data: { fine_Id: fine.fine_Id, offense_Id: offense.offense_Id },
        });
      }

      await tx.driving_License.update({
        where: { license_Id: data.licenseId },
        data: {
          points: {
            decrement: offenses.reduce((sum, off) => sum + off.points_Value, 0),
          },
          status: 'SUSPENDED',
        },
      });

      if (!isCourtCase) {
        await tx.temporary_License.create({
          data: { license_Id: data.licenseId, expiry_Date: fineDueDate },
        });
      }

      return fine;
    });
  }

  async getMyFines(userId: string) {
    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: userId },
    });
    if (!license) throw new NotFoundException('License not found');

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

  async payFine(fineId: string, amount: number, paymentMethod: string) {
    const fine = await this.prisma.fine.findUnique({
      where: { fine_Id: fineId },
    });
    if (!fine) throw new NotFoundException('Fine not found');
    if (fine.status === 'PAID')
      throw new BadRequestException('Fine is already paid');
    if (fine.status === 'OVERDUE')
      throw new BadRequestException(
        'Fine is overdue (Court Case). You cannot pay via the app.',
      );

    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.create({
        data: { fine_Id: fineId, amount: amount, status: 'COMPLETED' },
      });
      const updatedFine = await tx.fine.update({
        where: { fine_Id: fineId },
        data: { status: 'PAID' },
      });
      await tx.driving_License.update({
        where: { license_Id: fine.license_Id },
        data: { status: 'ACTIVE' },
      });
      await tx.temporary_License.deleteMany({
        where: { license_Id: fine.license_Id },
      });

      return {
        message: `Payment successful.`,
        paymentId: payment.payment_Id,
        fineStatus: updatedFine.status,
      };
    });
  }

  async payBulkFines(
    fineIds: string[],
    totalAmount: number,
    paymentMethod: string,
  ) {
    const fines = await this.prisma.fine.findMany({
      where: { fine_Id: { in: fineIds } },
    });
    if (fines.length !== fineIds.length)
      throw new BadRequestException('Some fines not found');

    for (const fine of fines) {
      if (fine.status === 'PAID')
        throw new BadRequestException(`Fine ${fine.fine_Id} already paid`);
      if (fine.status === 'OVERDUE')
        throw new BadRequestException(`Fine ${fine.fine_Id} is overdue`);
    }

    const licenseId = fines[0].license_Id;
    return this.prisma.$transaction(async (tx) => {
      const payments = [];
      for (const fineId of fineIds) {
        const p = await tx.payment.create({
          data: {
            fine_Id: fineId,
            amount: totalAmount / fineIds.length,
            status: 'COMPLETED',
          },
        });
        payments.push(p);
        await tx.fine.update({
          where: { fine_Id: fineId },
          data: { status: 'PAID' },
        });
      }
      await tx.driving_License.update({
        where: { license_Id: licenseId },
        data: { status: 'ACTIVE' },
      });
      await tx.temporary_License.deleteMany({
        where: { license_Id: licenseId },
      });
      return {
        message: 'Bulk payment successful',
        payments: payments.map((p) => p.payment_Id),
      };
    });
  }

  async updateCourtCase(fineId: string, verdict: 'ACTIVE' | 'REVOKED') {
    const fine = await this.prisma.fine.findUnique({
      where: { fine_Id: fineId },
    });
    if (!fine) throw new NotFoundException('Fine not found');

    return this.prisma.$transaction(async (tx) => {
      await tx.fine.update({
        where: { fine_Id: fineId },
        data: { status: 'PAID' },
      });
      return tx.driving_License.update({
        where: { license_Id: fine.license_Id },
        data: { status: verdict, points: verdict === 'ACTIVE' ? 24 : 0 },
      });
    });
  }

  async getAllOffenses() {
    return this.prisma.offence_Category.findMany({ orderBy: { code: 'asc' } });
  }

  async createOffenseCategory(data: CreateOffenseData, policeAdminId: string) {
    return this.prisma.offence_Category.create({
      data: {
        ...data,
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

  async deleteOffenseCategory(id: string) {
    return this.prisma.offence_Category.delete({ where: { offense_Id: id } });
  }

  async getCourtCasesByDH(headId: string) {
    const officers = await this.prisma.traffic_Officer.findMany({
      where: { divisional_Head_Id: headId },
      select: { traffic_Officer_Id: true },
    });
    const officerIds = officers.map((o) => o.traffic_Officer_Id);

    return this.prisma.fine.findMany({
      where: { status: 'OVERDUE', traffic_Officer_Id: { in: officerIds } },
      include: {
        license: {
          select: { license_No: true, full_Name: true, nic_No: true },
        },
        trafficOfficer: { select: { name: true, badge_No: true } },
        offenses: { include: { offenceCategory: true } },
      },
      orderBy: { issue_At: 'desc' },
    });
  }

  async getDashboardStats(headId: string) {
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

    return {
      totalOfficers: officers.length,
      activeOfficersOnDuty: officers.filter((o) => o.shifts.length > 0).length,
      totalFinesIssued: fines.length,
      pendingFinesCount: fines.filter((f) => f.status === 'PENDING').length,
      overdueCourtCases: fines.filter((f) => f.status === 'OVERDUE').length,
      totalRevenue: fines
        .filter((f) => f.status === 'PAID' && f.payment)
        .reduce((sum, f) => sum + f.payment.amount, 0),
    };
  }
}
