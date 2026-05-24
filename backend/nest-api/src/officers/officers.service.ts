import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class OfficersService {
  constructor(private prisma: PrismaService) {}

  async registerOfficer(data: {
    badgeNumber: string;
    name: string;
    password: string;
    districtName: string;
  }) {
    const existingOfficer = await this.prisma.officer.findUnique({
      where: { badgeNumber: data.badgeNumber },
    });

    if (existingOfficer) {
      throw new BadRequestException(
        'An officer with this badge number already exists.',
      );
    }

    let district = await this.prisma.district.findUnique({
      where: { name: data.districtName },
    });

    if (!district) {
      district = await this.prisma.district.create({
        data: { name: data.districtName },
      });
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

    const newOfficer = await this.prisma.officer.create({
      data: {
        badgeNumber: data.badgeNumber,
        name: data.name,
        password: hashedPassword,
        role: 'TRAFFIC_OFFICER',
        districtId: district.id,
      },
    });

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...result } = newOfficer;
    return result;
  }
}
