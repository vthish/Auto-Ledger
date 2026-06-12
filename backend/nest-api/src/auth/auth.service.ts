import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { User, DMT_Admin, Police_Admin } from '@prisma/client';
import * as bcrypt from 'bcrypt';

export interface RegisterData {
  nicNo: string;
  name: string;
  mobilePhoneNo: string;
  password: string;
  deviceId: string;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async loginAdmin(adminId: string, pass: string, type: 'DMT' | 'POLICE') {
    let admin: DMT_Admin | Police_Admin | null = null;
    let roleName = '';

    if (type === 'DMT') {
      admin = await this.prisma.dMT_Admin.findUnique({
        where: { dmt_Admin_Id: adminId },
      });
      roleName = 'DMT_ADMIN';
    } else {
      admin = await this.prisma.police_Admin.findUnique({
        where: { police_Admin_Id: adminId },
      });
      roleName = 'POLICE_ADMIN';
    }

    if (!admin)
      throw new UnauthorizedException('Invalid Admin ID or password.');

    const isPasswordValid = await bcrypt.compare(pass, admin.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid Admin ID or password.');

    const adminIdValue =
      type === 'DMT'
        ? (admin as DMT_Admin).dmt_Admin_Id
        : (admin as Police_Admin).police_Admin_Id;

    const payload = { sub: adminIdValue, role: roleName };
    return {
      accessToken: this.jwtService.sign(payload),
      user: { id: payload.sub, name: admin.name, role: roleName },
    };
  }

  async loginHead(headId: string, pass: string) {
    const head = await this.prisma.divisional_Head.findUnique({
      where: { divisional_Head_Id: headId },
    });

    if (!head) throw new UnauthorizedException('Invalid Head ID or password.');

    const isPasswordValid = await bcrypt.compare(pass, head.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid Head ID or password.');

    const payload = {
      sub: head.divisional_Head_Id,
      role: head.role,
      divisionId: head.division_Id,
    };
    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: head.divisional_Head_Id,
        name: head.name,
        role: head.role,
        divisionId: head.division_Id,
      },
    };
  }

  async loginOfficer(badgeNo: string, pass: string) {
    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { badge_No: badgeNo },
    });

    if (!officer)
      throw new UnauthorizedException('Invalid Badge Number or password.');

    const isPasswordValid = await bcrypt.compare(pass, officer.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid Badge Number or password.');

    const payload = {
      sub: officer.traffic_Officer_Id,
      role: officer.role,
      badgeNo: officer.badge_No,
      headId: officer.divisional_Head_Id,
    };
    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: officer.traffic_Officer_Id,
        name: officer.name,
        role: officer.role,
        badgeNo: officer.badge_No,
      },
    };
  }

  private generateUserToken(user: User) {
    const payload = { sub: user.user_Id, nic: user.nic_No, role: 'USER' };
    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: user.user_Id,
        name: user.name,
        nic: user.nic_No,
        phoneNumber: user.mobile_Phone_No,
        isPhoneVerified: user.isPhoneVerified,
      },
    };
  }

  async registerUser(data: RegisterData) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: data.nicNo },
    });

    if (!user) {
      throw new BadRequestException(
        'Registration Failed: No driving license found for this NIC.',
      );
    }

    const license = await this.prisma.driving_License.findUnique({
      where: { user_Id: user.user_Id },
    });

    if (!license) {
      throw new BadRequestException(
        'Registration Failed: No driving license found for this NIC.',
      );
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

    const updatedUser = await this.prisma.user.update({
      where: { nic_No: data.nicNo },
      data: {
        name: data.name,
        mobile_Phone_No: data.mobilePhoneNo,
        password: hashedPassword,
        device_Id: data.deviceId,
        isPhoneVerified: true,
      },
    });

    return this.generateUserToken(updatedUser);
  }

  async loginUser(nicNo: string, pass: string, deviceId: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user) throw new UnauthorizedException('Invalid NIC or password.');

    const isPasswordValid = await bcrypt.compare(pass, user.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid NIC or password.');

    if (user.device_Id !== deviceId) {
      throw new UnauthorizedException(
        'Access Denied: You can only log in from your registered device.',
      );
    }

    return this.generateUserToken(user);
  }

  async verifyNewDevice(nicNo: string, newDeviceId: string) {
    const user = await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: {
        device_Id: newDeviceId,
        isPhoneVerified: true,
      },
    });

    return this.generateUserToken(user);
  }
}
