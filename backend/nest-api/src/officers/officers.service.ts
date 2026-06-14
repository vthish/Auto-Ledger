import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { UpdateShiftDto } from './officers.controller';

@Injectable()
export class OfficersService {
  constructor(private prisma: PrismaService) {}

  async createDivision(
    divisionId: string,
    divisionName: string,
    policeAdminId: string,
  ) {
    const existingId = await this.prisma.division.findUnique({
      where: { division_Id: divisionId },
    });
    if (existingId) throw new BadRequestException('Division ID already exists');

    const existingDivision = await this.prisma.division.findUnique({
      where: { division_Name: divisionName },
    });
    if (existingDivision)
      throw new BadRequestException('Division name already exists');

    return this.prisma.division.create({
      data: {
        division_Id: divisionId,
        division_Name: divisionName,
        police_Admin_Id: policeAdminId,
      },
    });
  }

  async createDivisionalHead(data: {
    divisionName: string;
    username: string;
    email: string;
    name: string;
    passwordStr: string;
  }) {
    const existingDivision = await this.prisma.division.findUnique({
      where: { division_Name: data.divisionName },
      include: { divisionalHead: true },
    });
    if (!existingDivision) throw new NotFoundException('Division not found');
    if (existingDivision.divisionalHead)
      throw new BadRequestException(
        'This Division already has a Head assigned',
      );
    const existingUsername = await this.prisma.divisional_Head.findUnique({
      where: { username: data.username },
    });
    if (existingUsername)
      throw new BadRequestException('Head username already exists');
    const existingEmail = await this.prisma.divisional_Head.findUnique({
      where: { email: data.email },
    });
    if (existingEmail)
      throw new BadRequestException('Head email already exists');
    const hashedPassword = await bcrypt.hash(data.passwordStr, 10);
    return this.prisma.divisional_Head.create({
      data: {
        username: data.username,
        email: data.email,
        name: data.name,
        division_Id: existingDivision.division_Id,
        password: hashedPassword,
        role: 'DIVISIONAL_HEAD',
      },
    });
  }

  async createTrafficOfficer(data: {
    badgeNo: string;
    email: string;
    name: string;
    passwordStr: string;
    headId: string;
  }) {
    const existingBadge = await this.prisma.traffic_Officer.findUnique({
      where: { badge_No: data.badgeNo },
    });
    if (existingBadge)
      throw new BadRequestException('Badge number already exists');
    const existingEmail = await this.prisma.traffic_Officer.findUnique({
      where: { email: data.email },
    });
    if (existingEmail)
      throw new BadRequestException('Officer email already exists');
    const hashedPassword = await bcrypt.hash(data.passwordStr, 10);
    return this.prisma.traffic_Officer.create({
      data: {
        badge_No: data.badgeNo,
        email: data.email,
        name: data.name,
        password: hashedPassword,
        divisional_Head_Id: data.headId,
        role: 'TRAFFIC_OFFICER',
      },
    });
  }

  async assignShift(data: {
    officerId: string;
    date: Date;
    startTime: Date;
    endTime: Date;
    location: string;
  }) {
    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { traffic_Officer_Id: data.officerId },
    });
    if (!officer) throw new NotFoundException('Officer not found');
    return this.prisma.shift.create({
      data: {
        traffic_Officer_Id: data.officerId,
        date: data.date,
        start_Time: data.startTime,
        end_Time: data.endTime,
        location: data.location,
        is_Active: true,
      },
    });
  }

  async updateShift(shiftId: string, updateShiftDto: UpdateShiftDto) {
    const shift = await this.prisma.shift.findUnique({
      where: { shift_Id: shiftId },
    });
    if (!shift) throw new NotFoundException('Shift not found');

    const updateData: {
      date?: Date;
      start_Time?: Date;
      end_Time?: Date;
      location?: string;
    } = {};
    if (updateShiftDto.date) updateData.date = updateShiftDto.date;
    if (updateShiftDto.startTime)
      updateData.start_Time = updateShiftDto.startTime;
    if (updateShiftDto.endTime) updateData.end_Time = updateShiftDto.endTime;
    if (updateShiftDto.location) updateData.location = updateShiftDto.location;

    return this.prisma.shift.update({
      where: { shift_Id: shiftId },
      data: updateData,
    });
  }

  async getOfficerShifts(officerId: string) {
    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { traffic_Officer_Id: officerId },
    });
    if (!officer) throw new NotFoundException('Officer not found');
    return this.prisma.shift.findMany({
      where: { traffic_Officer_Id: officerId },
      orderBy: { start_Time: 'desc' },
    });
  }

  async getDivisionOfficers(headId: string, search?: string) {
    const whereClause: {
      divisional_Head_Id: string;
      OR?: { [key: string]: { contains: string; mode: 'insensitive' } }[];
    } = { divisional_Head_Id: headId };

    if (search) {
      whereClause.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { badge_No: { contains: search, mode: 'insensitive' } },
      ];
    }

    const now = new Date();
    const officers = await this.prisma.traffic_Officer.findMany({
      where: whereClause,
      select: {
        traffic_Officer_Id: true,
        name: true,
        badge_No: true,
        email: true,
        shifts: {
          where: {
            start_Time: { lte: now },
            end_Time: { gte: now },
            is_Active: true,
          },
        },
      },
    });

    return officers.map((off) => ({
      ...off,
      status: off.shifts.length > 0 ? 'ON_DUTY' : 'OFF_DUTY',
      currentShift: off.shifts.length > 0 ? off.shifts[0] : null,
    }));
  }
}
