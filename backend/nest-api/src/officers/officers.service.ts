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

  async createDivisionWithHead(
    divisionName: string,
    policeAdminId: string,
    headUsername: string,
    headName: string,
    headPasswordStr: string,
  ) {
    const existingDivision = await this.prisma.division.findUnique({
      where: { division_Name: divisionName },
    });
    if (existingDivision)
      throw new BadRequestException('Division name already exists');

    const existingHead = await this.prisma.divisional_Head.findUnique({
      where: { username: headUsername },
    });
    if (existingHead)
      throw new BadRequestException('Head username already exists');

    const hashedPassword = await bcrypt.hash(headPasswordStr, 10);

    return this.prisma.$transaction(async (tx) => {
      const division = await tx.division.create({
        data: {
          division_Name: divisionName,
          police_Admin_Id: policeAdminId,
        },
      });

      const head = await tx.divisional_Head.create({
        data: {
          username: headUsername,
          name: headName,
          division_Id: division.division_Id,
          password: hashedPassword,
          role: 'DIVISIONAL_HEAD',
        },
      });

      return { division, head };
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
