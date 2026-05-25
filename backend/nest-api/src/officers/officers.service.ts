import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { OfficerRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

@Injectable()
export class OfficersService {
  constructor(private prisma: PrismaService) {}

  async registerDivisionalHead(data: {
    badgeNumber: string;
    name: string;
    password: string;
    districtName: string;
  }) {
    const districtCount = await this.prisma.district.count();
    let district = await this.prisma.district.findUnique({
      where: { name: data.districtName },
    });

    if (!district && districtCount >= 25) {
      throw new BadRequestException(
        'Maximum limit of 25 districts reached in Sri Lanka.',
      );
    }

    if (!district) {
      district = await this.prisma.district.create({
        data: { name: data.districtName },
      });
    }

    if (district.headOfficerId) {
      throw new BadRequestException(
        `District ${data.districtName} already has an assigned Divisional Head.`,
      );
    }

    const existingOfficer = await this.prisma.officer.findUnique({
      where: { badgeNumber: data.badgeNumber },
    });

    if (existingOfficer) {
      throw new BadRequestException('Badge number already exists.');
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

    const newHead = await this.prisma.officer.create({
      data: {
        badgeNumber: data.badgeNumber,
        name: data.name,
        password: hashedPassword,
        role: OfficerRole.DIVISIONAL_HEAD,
        districtId: district.id,
      },
    });

    await this.prisma.district.update({
      where: { id: district.id },
      data: { headOfficerId: newHead.id },
    });

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...result } = newHead;
    return result;
  }

  async registerOfficer(data: {
    badgeNumber: string;
    name: string;
    password: string;
    districtId: string;
  }) {
    const existingOfficer = await this.prisma.officer.findUnique({
      where: { badgeNumber: data.badgeNumber },
    });

    if (existingOfficer) {
      throw new BadRequestException(
        'An officer with this badge number already exists.',
      );
    }

    const district = await this.prisma.district.findUnique({
      where: { id: data.districtId },
    });

    if (!district) {
      throw new NotFoundException(
        'District not found. Divisional Head must be registered first.',
      );
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

    const newOfficer = await this.prisma.officer.create({
      data: {
        badgeNumber: data.badgeNumber,
        name: data.name,
        password: hashedPassword,
        role: OfficerRole.TRAFFIC_OFFICER,
        districtId: district.id,
      },
    });

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...result } = newOfficer;
    return result;
  }

  async assignShift(data: {
    officerId: string;
    startTime: string;
    endTime: string;
  }) {
    const officer = await this.prisma.officer.findUnique({
      where: { id: data.officerId },
    });

    if (!officer) {
      throw new NotFoundException('Officer not found.');
    }

    await this.prisma.shift.updateMany({
      where: { officerId: data.officerId, isActive: true },
      data: { isActive: false },
    });

    return this.prisma.shift.create({
      data: {
        officerId: data.officerId,
        startTime: new Date(data.startTime),
        endTime: new Date(data.endTime),
        isActive: true,
      },
    });
  }

  async getOfficersByDistrict(districtId: string) {
    return this.prisma.officer.findMany({
      where: { districtId, role: OfficerRole.TRAFFIC_OFFICER },
      select: {
        id: true,
        badgeNumber: true,
        name: true,
        role: true,
        shifts: { where: { isActive: true } },
      },
    });
  }
}
