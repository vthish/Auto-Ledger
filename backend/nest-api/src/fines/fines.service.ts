import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FinesService {
  constructor(private prisma: PrismaService) {}

  // 1. Issue a Fine
  async issueFine(data: {
    licenseId: string;
    officerId: string;
    offenseIds: string[];
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

    let isCourtCase = offenses.some((o) => o.is_Court_Case);
    const fineDueDate = new Date();
    fineDueDate.setDate(fineDueDate.getDate() + 14);

    return this.prisma.$transaction(async (tx) => {
      // Create the fine
      const fine = await tx.fine.create({
        data: {
          license_Id: data.licenseId,
          traffic_Officer_Id: data.officerId,
          due_Date: fineDueDate,
          status: 'PENDING',
        },
      });

      // Link offences to the bridge table
      for (const offense of offenses) {
        await tx.fine_Offence.create({
          data: { fine_Id: fine.fine_Id, offense_Id: offense.offense_Id },
        });
      }

      // If NOT a court case, issue Temporary License
      if (!isCourtCase) {
        await tx.temporary_License.create({
          data: {
            license_Id: data.licenseId,
            expiry_Date: fineDueDate,
          },
        });
      }

      // Deduct Points
      const totalPoints = offenses.reduce(
        (sum, off) => sum + off.points_Value,
        0,
      );
      await tx.driving_License.update({
        where: { license_Id: data.licenseId },
        data: { points: { decrement: totalPoints } },
      });

      return fine;
    });
  }

  // 2. Get My Fines (Driver App)
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

  // 3. Process Court Case Verdict (Divisional Head)
  async updateCourtCase(fineId: string, verdict: 'ACTIVE' | 'REVOKED') {
    const fine = await this.prisma.fine.findUnique({
      where: { fine_Id: fineId },
    });
    if (!fine) throw new NotFoundException('Fine not found');

    return this.prisma.$transaction(async (tx) => {
      // Mark fine as paid/closed
      await tx.fine.update({
        where: { fine_Id: fineId },
        data: { status: 'PAID' },
      });

      // Update license status and reset points if ACTIVE
      return tx.driving_License.update({
        where: { license_Id: fine.license_Id },
        data: {
          status: verdict,
          points: verdict === 'ACTIVE' ? 24 : 0,
        },
      });
    });
  }
}
