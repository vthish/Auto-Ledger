import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async login(badgeNumber: string, pass: string) {
    const officer = await this.prisma.officer.findUnique({
      where: { badgeNumber },
    });

    if (!officer) {
      throw new UnauthorizedException('Invalid badge number or password.');
    }

    const isPasswordValid = await bcrypt.compare(pass, officer.password);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid badge number or password.');
    }

    const payload = {
      sub: officer.id,
      badgeNumber: officer.badgeNumber,
      role: officer.role,
      districtId: officer.districtId,
    };

    return {
      accessToken: this.jwtService.sign(payload),
      officer: {
        id: officer.id,
        name: officer.name,
        role: officer.role,
        districtId: officer.districtId,
      },
    };
  }
}
