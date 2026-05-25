import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';
import * as bcrypt from 'bcrypt';

export interface RegisterUserDto {
  nic: string;
  name: string;
  phoneNumber: string;
  password: string;
  deviceId: string;
}

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

  private generateUserToken(user: User) {
    const payload = {
      sub: user.id,
      nic: user.nic,
      role: 'USER',
    };
    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: user.id,
        name: user.name,
        nic: user.nic,
        phoneNumber: user.phoneNumber,
        isPhoneVerified: user.isPhoneVerified,
      },
    };
  }

  async registerUser(data: RegisterUserDto) {
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [{ nic: data.nic }, { phoneNumber: data.phoneNumber }],
      },
    });

    if (existingUser) {
      throw new UnauthorizedException('NIC or Phone Number already exists.');
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

    const user = await this.prisma.user.create({
      data: {
        nic: data.nic,
        name: data.name,
        phoneNumber: data.phoneNumber,
        password: hashedPassword,
        deviceId: data.deviceId,
        isPhoneVerified: true,
      },
    });

    return this.generateUserToken(user);
  }

  async loginUser(nic: string, pass: string, deviceId: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid NIC or password.');
    }

    const isPasswordValid = await bcrypt.compare(pass, user.password);

    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid NIC or password.');
    }

    if (user.deviceId !== deviceId) {
      return {
        status: 'OTP_REQUIRED',
        message: 'New device detected. Please verify with OTP.',
        nic: user.nic,
      };
    }

    return this.generateUserToken(user);
  }

  async verifyNewDevice(nic: string, newDeviceId: string) {
    const user = await this.prisma.user.update({
      where: { nic },
      data: {
        deviceId: newDeviceId,
        isPhoneVerified: true,
      },
    });

    return this.generateUserToken(user);
  }
}
