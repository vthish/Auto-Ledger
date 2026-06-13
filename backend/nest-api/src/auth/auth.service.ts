import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import {
  User,
  DMT_Admin,
  Police_Admin,
  Divisional_Head,
  Traffic_Officer,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { ChangePasswordDto } from './auth.controller';

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

  async loginAdmin(name: string, pass: string, type: 'DMT' | 'POLICE') {
    let adminObj: DMT_Admin | Police_Admin | null = null;
    let roleName = '';

    if (type === 'DMT') {
      // Find the first matching DMT Admin by name
      adminObj = await this.prisma.dMT_Admin.findFirst({
        where: { name: name },
      });
      roleName = 'DMT_ADMIN';
    } else {
      // Find the first matching Police Admin by name
      adminObj = await this.prisma.police_Admin.findFirst({
        where: { name: name },
      });
      roleName = 'POLICE_ADMIN';
    }

    if (!adminObj)
      throw new UnauthorizedException('Invalid Admin Name or password.');

    const isPasswordValid = await bcrypt.compare(pass, adminObj.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid Admin Name or password.');

    const adminIdValue =
      type === 'DMT'
        ? (adminObj as DMT_Admin).dmt_Admin_Id
        : (adminObj as Police_Admin).police_Admin_Id;

    const payload = { sub: adminIdValue, role: roleName };
    return {
      accessToken: this.jwtService.sign(payload),
      user: { id: payload.sub, name: adminObj.name, role: roleName },
    };
  }

  async loginHead(name: string, pass: string) {
    // Find the first matching Divisional Head by name
    const head = await this.prisma.divisional_Head.findFirst({
      where: { name: name },
    });

    if (!head)
      throw new UnauthorizedException('Invalid Head Name or password.');

    const isPasswordValid = await bcrypt.compare(pass, head.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid Head Name or password.');

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
      include: { shifts: true },
    });

    if (!officer)
      throw new UnauthorizedException('Invalid Badge Number or password.');

    const isPasswordValid = await bcrypt.compare(pass, officer.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid Badge Number or password.');

    const now = new Date();
    const activeShift = officer.shifts.find(
      (shift) =>
        shift.is_Active &&
        new Date(shift.start_Time) <= now &&
        new Date(shift.end_Time) >= now,
    );

    if (!activeShift) {
      throw new ForbiddenException(
        'Access Denied: You are not within an active shift schedule.',
      );
    }

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

  async changePassword(userId: string, role: string, dto: ChangePasswordDto) {
    let user: Divisional_Head | Traffic_Officer | null = null;

    if (role === 'DIVISIONAL_HEAD') {
      user = await this.prisma.divisional_Head.findUnique({
        where: { divisional_Head_Id: userId },
      });
    } else if (role === 'TRAFFIC_OFFICER') {
      user = await this.prisma.traffic_Officer.findUnique({
        where: { traffic_Officer_Id: userId },
      });
    } else {
      throw new BadRequestException('Invalid role for password change');
    }

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isPasswordValid = await bcrypt.compare(
      dto.oldPassword,
      user.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid old password');
    }

    const hashedNewPassword = await bcrypt.hash(dto.newPassword, 10);

    if (role === 'DIVISIONAL_HEAD') {
      await this.prisma.divisional_Head.update({
        where: { divisional_Head_Id: userId },
        data: { password: hashedNewPassword },
      });
    } else {
      await this.prisma.traffic_Officer.update({
        where: { traffic_Officer_Id: userId },
        data: { password: hashedNewPassword },
      });
    }

    return { message: 'Password changed successfully' };
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

    await this.prisma.user.update({
      where: { nic_No: data.nicNo },
      data: {
        name: data.name,
        mobile_Phone_No: data.mobilePhoneNo,
        password: hashedPassword,
        device_Id: data.deviceId,
        isPhoneVerified: false,
      },
    });

    return {
      message:
        'User details saved. Please verify phone number via Firebase SMS to complete registration.',
      success: true,
    };
  }

  async verifyRegistration(nicNo: string) {
    const user = await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: { isPhoneVerified: true },
    });

    return this.generateUserToken(user);
  }

  async loginUser(nicNo: string, pass: string, deviceId: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user) throw new UnauthorizedException('Invalid NIC or password.');

    if (!user.isPhoneVerified) {
      throw new ForbiddenException(
        'Please verify your phone number using OTP first.',
      );
    }

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

  async biometricLogin(nicNo: string, deviceId: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user) throw new UnauthorizedException('Invalid user.');

    if (!user.isPhoneVerified) {
      throw new ForbiddenException(
        'Please verify your phone number using OTP first.',
      );
    }

    if (user.device_Id !== deviceId) {
      throw new UnauthorizedException(
        'Biometric Access Denied: Unrecognized device.',
      );
    }

    return this.generateUserToken(user);
  }

  async changeUserPassword(
    userId: string,
    dto: { oldPassword: string; newPassword: string },
  ) {
    const user = await this.prisma.user.findUnique({
      where: { user_Id: userId },
    });

    if (!user) throw new NotFoundException('User not found');

    const isPasswordValid = await bcrypt.compare(
      dto.oldPassword,
      user.password,
    );
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid old password');
    }

    const hashedNewPassword = await bcrypt.hash(dto.newPassword, 10);

    await this.prisma.user.update({
      where: { user_Id: userId },
      data: { password: hashedNewPassword },
    });

    return { message: 'User password changed successfully' };
  }

  async requestPasswordReset(nicNo: string, mobilePhoneNo: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user || user.mobile_Phone_No !== mobilePhoneNo) {
      throw new BadRequestException('Invalid NIC or Mobile Number provided.');
    }

    return {
      message: 'NIC and Phone Match. You can proceed to request Firebase SMS.',
      success: true,
    };
  }

  async resetPassword(
    nicNo: string,
    mobilePhoneNo: string,
    newPasswordStr: string,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user || user.mobile_Phone_No !== mobilePhoneNo) {
      throw new BadRequestException('Invalid NIC or Mobile Number provided.');
    }

    const hashedNewPassword = await bcrypt.hash(newPasswordStr, 10);

    await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: { password: hashedNewPassword },
    });

    return {
      message: 'Password has been reset successfully. You can now login.',
    };
  }
}
