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

  async createDivisionalHead(data: {
    name: string;
    divisionId: string;
    passwordStr: string;
  }) {
    const existingHead = await this.prisma.divisional_Head.findUnique({
      where: { division_Id: data.divisionId },
    });
    if (existingHead)
      throw new BadRequestException('Division already has a head');

    const hashedPassword = await bcrypt.hash(data.passwordStr, 10);

    return this.prisma.divisional_Head.create({
      data: {
        name: data.name,
        division_Id: data.divisionId,
        password: hashedPassword,
        role: 'DIVISIONAL_HEAD',
      },
    });
  }

  async createTrafficOfficer(data: {
    badgeNo: string;
    name: string;
    passwordStr: string;
    headId: string;
  }) {
    const existingOfficer = await this.prisma.traffic_Officer.findUnique({
      where: { badge_No: data.badgeNo },
    });
    if (existingOfficer)
      throw new BadRequestException('Badge number already exists');

    const hashedPassword = await bcrypt.hash(data.passwordStr, 10);

    return this.prisma.traffic_Officer.create({
      data: {
        badge_No: data.badgeNo,
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

    if (!shift) {
      throw new NotFoundException('Shift not found');
    }

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
}
