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
          data: {
            license_Id: data.licenseId,
            expiry_Date: fineDueDate,
          },
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

    if (fine.status === 'OVERDUE') {
      throw new BadRequestException(
        'Fine is overdue (Court Case). You cannot pay via the app. Please contact the Divisional Head.',
      );
    }

    await new Promise((resolve) => setTimeout(resolve, 1000));

    return this.prisma.$transaction(async (tx) => {
      const payment = await tx.payment.create({
        data: {
          fine_Id: fineId,
          amount: amount,
          status: 'COMPLETED',
        },
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
        message: `Payment of Rs.${amount} via ${paymentMethod} processed successfully. Original License is now ACTIVE.`,
        paymentId: payment.payment_Id,
        fineStatus: updatedFine.status,
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
        data: {
          status: verdict,
          points: verdict === 'ACTIVE' ? 24 : 0,
        },
      });
    });
  }

  async getAllOffenses() {
    return this.prisma.offence_Category.findMany({
      orderBy: { code: 'asc' },
    });
  }

  async createOffenseCategory(data: CreateOffenseData, policeAdminId: string) {
    return this.prisma.offence_Category.create({
      data: {
        code: data.code,
        name: data.name,
        points_Value: data.points,
        amount: data.amount,
        is_Court_Case: data.isCourtCase,
        police_Admin_Id: policeAdminId,
      },
    });
  }

  async updateOffenseCategory(offenseId: string, data: UpdateOffenseData) {
    const existing = await this.prisma.offence_Category.findUnique({
      where: { offense_Id: offenseId },
    });
    if (!existing) throw new NotFoundException('Offense Category not found');

    return this.prisma.offence_Category.update({
      where: { offense_Id: offenseId },
      data: {
        name: data.name ?? existing.name,
        points_Value: data.points ?? existing.points_Value,
        amount: data.amount ?? existing.amount,
        is_Court_Case: data.isCourtCase ?? existing.is_Court_Case,
      },
    });
  }

  async deleteOffenseCategory(offenseId: string) {
    const existing = await this.prisma.offence_Category.findUnique({
      where: { offense_Id: offenseId },
    });
    if (!existing) throw new NotFoundException('Offense Category not found');

    return this.prisma.offence_Category.delete({
      where: { offense_Id: offenseId },
    });
  }
}
