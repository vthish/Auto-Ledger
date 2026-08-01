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
import * as nodemailer from 'nodemailer';
import { ChangePasswordDto } from './auth.controller';

export interface RegisterData {
  nicNo: string;
  name: string;
  email: string;
  password: string;
  deviceId: string;
}

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  private async sendOtpEmail(
    email: string,
    otp: string,
    type: 'registration' | 'reset' | 'device_verification',
  ): Promise<void> {
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    let subject = '';
    let text = '';
    let html = '';

    if (type === 'registration') {
      subject = '✅ Auto-Ledger: Verify Your Email Address';
      text = `Welcome to Auto-Ledger!\n\nYour verification OTP is: ${otp}\n\nThis code will expire in 5 minutes.\n\nPlease enter this OTP in the app to complete your registration.\n\nIf you didn't register, please ignore this email.`;
      html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #0B0F19; color: #ffffff; border-radius: 12px;">
          <h2 style="color: #00bcd4; text-align: center;">✅ Auto-Ledger</h2>
          <h3 style="text-align: center;">Verify Your Email Address</h3>
          <p style="text-align: center; color: #cccccc;">Welcome to Auto-Ledger! Please verify your email address to complete registration.</p>
          <div style="background-color: #1a1f2e; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <h1 style="font-size: 48px; letter-spacing: 8px; color: #00bcd4; margin: 0;">${otp}</h1>
          </div>
          <p style="text-align: center; color: #aaaaaa;">This OTP is valid for <strong>5 minutes</strong>.</p>
          <hr style="border-color: #333;">
          <p style="text-align: center; color: #666666; font-size: 12px;">If you didn't request this, please ignore this email.</p>
          <p style="text-align: center; color: #666666; font-size: 12px;">© 2026 Auto-Ledger</p>
        </div>
      `;
    } else if (type === 'reset') {
      subject = '🔑 Auto-Ledger: Password Reset OTP';
      text = `You requested to reset your Auto-Ledger password.\n\nYour password reset OTP is: ${otp}\n\nThis code will expire in 5 minutes.\n\nIf you didn't request a password reset, please ignore this email.`;
      html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #0B0F19; color: #ffffff; border-radius: 12px;">
          <h2 style="color: #ff6f00; text-align: center;">🔑 Auto-Ledger</h2>
          <h3 style="text-align: center;">Password Reset Request</h3>
          <p style="text-align: center; color: #cccccc;">You requested to reset your Auto-Ledger password.</p>
          <div style="background-color: #1a1f2e; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <h1 style="font-size: 48px; letter-spacing: 8px; color: #ff6f00; margin: 0;">${otp}</h1>
          </div>
          <p style="text-align: center; color: #aaaaaa;">This OTP is valid for <strong>5 minutes</strong>.</p>
          <hr style="border-color: #333;">
          <p style="text-align: center; color: #666666; font-size: 12px;">If you didn't request this, please ignore this email.</p>
          <p style="text-align: center; color: #666666; font-size: 12px;">© 2026 Auto-Ledger</p>
        </div>
      `;
    } else if (type === 'device_verification') {
      subject = '📱 Auto-Ledger: New Device Verification';
      text = `A new device is trying to access your Auto-Ledger account.\n\nYour device verification OTP is: ${otp}\n\nThis code will expire in 5 minutes.\n\nIf this wasn't you, please change your password immediately.`;
      html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #0B0F19; color: #ffffff; border-radius: 12px;">
          <h2 style="color: #4caf50; text-align: center;">📱 Auto-Ledger</h2>
          <h3 style="text-align: center;">New Device Verification</h3>
          <p style="text-align: center; color: #cccccc;">A new device is attempting to log into your account. Please use the OTP below to verify it.</p>
          <div style="background-color: #1a1f2e; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <h1 style="font-size: 48px; letter-spacing: 8px; color: #4caf50; margin: 0;">${otp}</h1>
          </div>
          <p style="text-align: center; color: #aaaaaa;">This OTP is valid for <strong>5 minutes</strong>.</p>
          <hr style="border-color: #333;">
          <p style="text-align: center; color: #666666; font-size: 12px;">If you didn't attempt to log in from a new device, please secure your account immediately.</p>
          <p style="text-align: center; color: #666666; font-size: 12px;">© 2026 Auto-Ledger</p>
        </div>
      `;
    }

    const mailOptions = {
      from: `"Auto-Ledger" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: subject,
      text: text,
      html: html,
    };

    await transporter.sendMail(mailOptions);
  }

  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  async loginAdmin(username: string, pass: string, type: 'DMT' | 'POLICE') {
    let adminObj: DMT_Admin | Police_Admin | null = null;
    let roleName = '';

    if (type === 'DMT') {
      adminObj = await this.prisma.dMT_Admin.findUnique({
        where: { username: username },
      });
      roleName = 'DMT_ADMIN';
    } else {
      adminObj = await this.prisma.police_Admin.findUnique({
        where: { username: username },
      });
      roleName = 'POLICE_ADMIN';
    }

    if (!adminObj)
      throw new UnauthorizedException('Invalid Admin Username or password.');

    const isPasswordValid = await bcrypt.compare(pass, adminObj.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid Admin Username or password.');

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

  async loginHead(username: string, pass: string) {
    const head = await this.prisma.divisional_Head.findUnique({
      where: { username: username },
    });

    if (!head || !head.is_Active)
      throw new UnauthorizedException('Invalid or inactive Head account.');

    const isPasswordValid = await bcrypt.compare(pass, head.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid Head Username or password.');

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
        email: head.email,
        role: head.role,
        divisionId: head.division_Id,
      },
    };
  }

  async loginOfficer(badgeNo: string, pass: string) {
    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { badge_No: badgeNo },
      include: {
        divisionalHead: {
          include: {
            division: true,
          },
        },
        shifts: true,
      },
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
        email: officer.email,
        role: officer.role,
        badgeNo: officer.badge_No,
        divisionName: officer.divisionalHead?.division?.division_Name || null,
        divisionalHeadName: officer.divisionalHead?.name || null,
        dutyLocation: activeShift.location,
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

  async requestHeadPasswordReset(username: string, email: string) {
    const head = await this.prisma.divisional_Head.findUnique({
      where: { username: username },
    });

    if (!head || head.email !== email || !head.is_Active) {
      throw new BadRequestException('Invalid Username or Email provided.');
    }

    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await this.prisma.divisional_Head.update({
      where: { username: username },
      data: { reset_Otp: otp, reset_Otp_Expires_At: expiresAt },
    });

    await this.sendOtpEmail(email, otp, 'reset');
    return { message: 'OTP sent successfully to your email.' };
  }

  async verifyHeadResetOtp(username: string, email: string, otp: string) {
    const head = await this.prisma.divisional_Head.findUnique({
      where: { username: username },
    });

    if (!head || head.email !== email) {
      throw new BadRequestException('Invalid Username or Email.');
    }
    if (head.reset_Otp !== otp) throw new BadRequestException('Invalid OTP.');
    if (!head.reset_Otp_Expires_At || new Date() > head.reset_Otp_Expires_At) {
      throw new BadRequestException('OTP has expired.');
    }

    return { success: true, message: 'OTP verified successfully.' };
  }

  async resetHeadPassword(
    username: string,
    email: string,
    otp: string,
    newPasswordStr: string,
  ) {
    const head = await this.prisma.divisional_Head.findUnique({
      where: { username: username },
    });

    if (!head || head.email !== email || head.reset_Otp !== otp) {
      throw new BadRequestException('Invalid OTP or Credentials.');
    }

    if (!head.reset_Otp_Expires_At || new Date() > head.reset_Otp_Expires_At) {
      throw new BadRequestException('OTP has expired.');
    }

    const hashedPassword = await bcrypt.hash(newPasswordStr, 10);

    await this.prisma.divisional_Head.update({
      where: { username: username },
      data: {
        password: hashedPassword,
        reset_Otp: null,
        reset_Otp_Expires_At: null,
      },
    });

    return { message: 'Divisional Head password reset successfully.' };
  }

  async resendHeadOtp(
    username: string,
    email: string,
  ): Promise<{ message: string }> {
    const head = await this.prisma.divisional_Head.findUnique({
      where: { username: username },
    });
    if (!head || head.email !== email || !head.is_Active) {
      throw new BadRequestException('Invalid Username or Email.');
    }
    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
    await this.prisma.divisional_Head.update({
      where: { username: username },
      data: { reset_Otp: otp, reset_Otp_Expires_At: expiresAt },
    });
    await this.sendOtpEmail(email, otp, 'reset');
    return { message: 'OTP resent successfully to your email.' };
  }

  async requestOfficerPasswordReset(badgeNo: string, email: string) {
    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { badge_No: badgeNo },
    });

    if (!officer || officer.email !== email) {
      throw new BadRequestException('Invalid Badge Number or Email provided.');
    }

    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await this.prisma.traffic_Officer.update({
      where: { badge_No: badgeNo },
      data: { reset_Otp: otp, reset_Otp_Expires_At: expiresAt },
    });

    await this.sendOtpEmail(email, otp, 'reset');
    return { message: 'OTP sent successfully to your email.' };
  }

  async verifyOfficerResetOtp(badgeNo: string, email: string, otp: string) {
    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { badge_No: badgeNo },
    });

    if (!officer || officer.email !== email) {
      throw new BadRequestException('Invalid Badge Number or Email.');
    }
    if (officer.reset_Otp !== otp)
      throw new BadRequestException('Invalid OTP.');
    if (
      !officer.reset_Otp_Expires_At ||
      new Date() > officer.reset_Otp_Expires_At
    ) {
      throw new BadRequestException('OTP has expired.');
    }

    return { success: true, message: 'OTP verified successfully.' };
  }

  async resetOfficerPassword(
    badgeNo: string,
    email: string,
    otp: string,
    newPasswordStr: string,
  ) {
    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { badge_No: badgeNo },
    });

    if (!officer || officer.email !== email || officer.reset_Otp !== otp) {
      throw new BadRequestException('Invalid OTP or Credentials.');
    }

    if (
      !officer.reset_Otp_Expires_At ||
      new Date() > officer.reset_Otp_Expires_At
    ) {
      throw new BadRequestException('OTP has expired.');
    }

    const hashedPassword = await bcrypt.hash(newPasswordStr, 10);

    await this.prisma.traffic_Officer.update({
      where: { badge_No: badgeNo },
      data: {
        password: hashedPassword,
        reset_Otp: null,
        reset_Otp_Expires_At: null,
      },
    });

    return { message: 'Traffic Officer password reset successfully.' };
  }

  async resendOfficerOtp(
    badgeNo: string,
    email: string,
  ): Promise<{ message: string }> {
    const officer = await this.prisma.traffic_Officer.findUnique({
      where: { badge_No: badgeNo },
    });
    if (!officer || officer.email !== email) {
      throw new BadRequestException('Invalid Badge Number or Email.');
    }
    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
    await this.prisma.traffic_Officer.update({
      where: { badge_No: badgeNo },
      data: { reset_Otp: otp, reset_Otp_Expires_At: expiresAt },
    });
    await this.sendOtpEmail(email, otp, 'reset');
    return { message: 'OTP resent successfully to your email.' };
  }

  private generateUserToken(user: User) {
    const payload = { sub: user.user_Id, nic: user.nic_No, role: 'USER' };
    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: user.user_Id,
        name: user.name,
        nic: user.nic_No,
        email: user.email,
        isEmailVerified: user.isEmailVerified,
      },
    };
  }

  async registerUser(data: RegisterData) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: data.nicNo },
    });

    if (!user) {
      throw new BadRequestException(
        'Registration Failed: No user found for this NIC.',
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
    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await this.prisma.user.update({
      where: { nic_No: data.nicNo },
      data: {
        name: data.name,
        email: data.email,
        password: hashedPassword,
        device_Id: data.deviceId,
        isEmailVerified: false,
        registration_Otp: otp,
        registration_Otp_Expires_At: expiresAt,
      },
    });

    await this.sendOtpEmail(data.email, otp, 'registration');

    return {
      message: 'OTP sent to your email. Please verify.',
      success: true,
    };
  }

  async verifyRegistration(nicNo: string, otp: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user) throw new BadRequestException('User not found.');
    if (user.registration_Otp !== otp)
      throw new BadRequestException('Invalid OTP.');
    if (
      !user.registration_Otp_Expires_At ||
      new Date() > user.registration_Otp_Expires_At
    ) {
      throw new BadRequestException('OTP has expired.');
    }

    const updatedUser = await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: {
        isEmailVerified: true,
        registration_Otp: null,
        registration_Otp_Expires_At: null,
      },
    });

    return this.generateUserToken(updatedUser);
  }

  async loginUser(nicNo: string, pass: string, deviceId: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user) throw new UnauthorizedException('Invalid NIC or password.');

    if (!user.isEmailVerified) {
      throw new ForbiddenException('Please verify your email using OTP first.');
    }

    const isPasswordValid = await bcrypt.compare(pass, user.password);
    if (!isPasswordValid)
      throw new UnauthorizedException('Invalid NIC or password.');

    if (user.device_Id !== deviceId) {
      throw new ForbiddenException({
        code: 'DEVICE_MISMATCH',
        message: 'New device detected. OTP verification required.',
        email: user.email,
      });
    }

    return this.generateUserToken(user);
  }

  async verifyNewDevice(nicNo: string, newDeviceId: string, otp: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user) throw new BadRequestException('User not found.');
    if (user.device_Otp !== otp) throw new BadRequestException('Invalid OTP.');
    if (
      !user.device_Otp_Expires_At ||
      new Date() > user.device_Otp_Expires_At
    ) {
      throw new BadRequestException('OTP has expired.');
    }

    const updatedUser = await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: {
        device_Id: newDeviceId,
        isEmailVerified: true,
        device_Otp: null,
        device_Otp_Expires_At: null,
      },
    });

    return this.generateUserToken(updatedUser);
  }

  async biometricLogin(nicNo: string, deviceId: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user) throw new UnauthorizedException('Invalid user.');

    if (!user.isEmailVerified) {
      throw new ForbiddenException('Please verify your email using OTP first.');
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

  async requestPasswordReset(nicNo: string, email: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user || user.email !== email) {
      throw new BadRequestException('Invalid NIC or Email provided.');
    }

    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: { reset_Otp: otp, reset_Otp_Expires_At: expiresAt },
    });

    await this.sendOtpEmail(email, otp, 'reset');
    return { message: 'OTP sent successfully to your email.' };
  }

  async verifyUserResetOtp(nicNo: string, email: string, otp: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user || user.email !== email) {
      throw new BadRequestException('Invalid NIC or Email.');
    }
    if (user.reset_Otp !== otp) throw new BadRequestException('Invalid OTP.');
    if (!user.reset_Otp_Expires_At || new Date() > user.reset_Otp_Expires_At) {
      throw new BadRequestException('OTP has expired.');
    }

    return { success: true, message: 'OTP verified successfully.' };
  }

  async resetPassword(
    nicNo: string,
    email: string,
    otp: string,
    newPasswordStr: string,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user || user.email !== email) {
      throw new BadRequestException('Invalid NIC or Email.');
    }

    if (user.reset_Otp !== otp) throw new BadRequestException('Invalid OTP.');
    if (!user.reset_Otp_Expires_At || new Date() > user.reset_Otp_Expires_At) {
      throw new BadRequestException('OTP has expired.');
    }

    const hashedNewPassword = await bcrypt.hash(newPasswordStr, 10);

    await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: {
        password: hashedNewPassword,
        reset_Otp: null,
        reset_Otp_Expires_At: null,
      },
    });

    return {
      message: 'Password has been reset successfully. You can now login.',
    };
  }

  async resendRegistrationOtp(nicNo: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user) {
      throw new BadRequestException('User not found.');
    }

    if (user.isEmailVerified) {
      throw new BadRequestException('Email already verified.');
    }

    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: {
        registration_Otp: otp,
        registration_Otp_Expires_At: expiresAt,
      },
    });

    await this.sendOtpEmail(user.email, otp, 'registration');
    return {
      message: 'OTP resent successfully. Please check your email.',
      success: true,
    };
  }

  async resendResetOtp(nicNo: string, email: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user || user.email !== email) {
      throw new BadRequestException('Invalid NIC or Email.');
    }

    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: {
        reset_Otp: otp,
        reset_Otp_Expires_At: expiresAt,
      },
    });

    await this.sendOtpEmail(email, otp, 'reset');
    return {
      message: 'OTP resent successfully. Please check your email.',
      success: true,
    };
  }

  async resendDeviceOtp(nicNo: string, email: string) {
    const user = await this.prisma.user.findUnique({
      where: { nic_No: nicNo },
    });

    if (!user || user.email !== email) {
      throw new BadRequestException('Invalid NIC or Email.');
    }

    const otp = this.generateOtp();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await this.prisma.user.update({
      where: { nic_No: nicNo },
      data: {
        device_Otp: otp,
        device_Otp_Expires_At: expiresAt,
      },
    });

    await this.sendOtpEmail(email, otp, 'device_verification');
    return {
      message: 'OTP resent successfully. Please check your email.',
      success: true,
    };
  }
}
