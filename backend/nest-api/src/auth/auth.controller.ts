import {
  Controller,
  Post,
  Patch,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import {
  ApiTags,
  ApiOperation,
  ApiProperty,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { JwtAuthGuard } from './jwt-auth.guard';
import { SkipDeviceCheck } from '../common/decorators/skip-device-check.decorator';
import {
  IsString,
  MinLength,
  Matches,
  IsEnum,
  IsNotEmpty,
  IsEmail,
} from 'class-validator';

const NIC_REGEX = /^(?:\d{9}[VvXx]|\d{12})$/;
const STRONG_PASSWORD_REGEX =
  /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

const NIC_VALIDATION_MESSAGE =
  'NIC must contain 9 digits followed by V/X or exactly 12 digits.';
const PASSWORD_VALIDATION_MESSAGE =
  'Password must be at least 8 characters and contain an uppercase letter, lowercase letter, number, and special character.';

export class AdminLoginDto {
  @ApiProperty({ example: 'mainpolice' })
  @IsString()
  @IsNotEmpty()
  username: string;

  @ApiProperty({ example: 'PoliceAdmin@Password123!' })
  @IsString()
  @IsNotEmpty()
  password: string;

  @ApiProperty({ example: 'DMT', enum: ['DMT', 'POLICE'] })
  @IsEnum(['DMT', 'POLICE'])
  type: 'DMT' | 'POLICE';
}

export class HeadLoginDto {
  @ApiProperty({ example: 'kamal_do' })
  @IsString()
  @IsNotEmpty()
  username: string;

  @ApiProperty({ example: 'Head@Pass123!' })
  @IsString()
  @IsNotEmpty()
  password: string;
}

export class OfficerLoginDto {
  @ApiProperty({ example: 'TRF-GALLE-100' })
  @IsString()
  @IsNotEmpty()
  badgeNo: string;

  @ApiProperty({ example: 'Officer@Pass123!' })
  @IsString()
  @IsNotEmpty()
  password: string;
}

export class RegisterUserDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: 'K.V.V. Thishan' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'Driver@Pass123!' })
  @IsString()
  @MinLength(8)
  @Matches(STRONG_PASSWORD_REGEX, {
    message: PASSWORD_VALIDATION_MESSAGE,
  })
  password: string;

  @ApiProperty({ example: 'PHONE-MAC-001' })
  @IsString()
  @IsNotEmpty()
  deviceId: string;
}

export class VerifyRegistrationDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @IsNotEmpty()
  otp: string;
}

export class UserLoginDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: 'Driver@Pass123!' })
  @IsString()
  @IsNotEmpty()
  password: string;

  @ApiProperty({ example: 'PHONE-MAC-001' })
  @IsString()
  @IsNotEmpty()
  deviceId: string;
}

export class VerifyDeviceDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: 'NEW-PHONE-MAC-002' })
  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @IsNotEmpty()
  otp: string;
}

export class ChangePasswordDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  oldPassword: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  @Matches(STRONG_PASSWORD_REGEX, {
    message: PASSWORD_VALIDATION_MESSAGE,
  })
  newPassword: string;
}

export class BiometricLoginDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: 'PHONE-MAC-001' })
  @IsString()
  @IsNotEmpty()
  deviceId: string;
}

export class ForgotPasswordRequestDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;
}

export class VerifyResetOtpDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @IsNotEmpty()
  otp: string;
}

export class ResetPasswordDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @IsNotEmpty()
  otp: string;

  @ApiProperty({ example: 'NewDriver@Pass123!' })
  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  @Matches(STRONG_PASSWORD_REGEX, {
    message: PASSWORD_VALIDATION_MESSAGE,
  })
  newPassword: string;
}

export class HeadForgotPasswordRequestDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  username: string;

  @ApiProperty()
  @IsEmail()
  @IsNotEmpty()
  email: string;
}

export class HeadVerifyResetOtpDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  username: string;

  @ApiProperty()
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  otp: string;
}

export class HeadResetPasswordDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  username: string;

  @ApiProperty()
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  otp: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  newPasswordStr: string;
}

export class OfficerForgotPasswordRequestDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  badgeNo: string;

  @ApiProperty()
  @IsEmail()
  @IsNotEmpty()
  email: string;
}

export class OfficerVerifyResetOtpDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  badgeNo: string;

  @ApiProperty()
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  otp: string;
}

export class OfficerResetPasswordDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  badgeNo: string;

  @ApiProperty()
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  otp: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  newPasswordStr: string;
}

export class ResendRegistrationOtpDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;
}

export class ResendResetOtpDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;
}

export class ResendDeviceOtpDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
  nicNo: string;

  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;
}

export class ResendHeadOtpDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  username: string;

  @ApiProperty()
  @IsEmail()
  @IsNotEmpty()
  email: string;
}

export class ResendOfficerOtpDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  badgeNo: string;

  @ApiProperty()
  @IsEmail()
  @IsNotEmpty()
  email: string;
}

export interface AuthRequest {
  user: {
    id: string;
    role: string;
  };
}

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Login for DMT & Police Admins' })
  @Post('admin/login')
  async loginAdmin(@Body() data: AdminLoginDto) {
    return await this.authService.loginAdmin(
      data.username,
      data.password,
      data.type,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Login for Divisional Heads' })
  @Post('head/login')
  async loginHead(@Body() data: HeadLoginDto) {
    return await this.authService.loginHead(data.username, data.password);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Login for Traffic Officers' })
  @Post('officer/login')
  async loginOfficer(@Body() data: OfficerLoginDto) {
    return await this.authService.loginOfficer(data.badgeNo, data.password);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Step 1: Register a new driver' })
  @Post('user/register')
  async registerUser(@Body() data: RegisterUserDto) {
    return await this.authService.registerUser(data);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Step 2: Complete Registration with OTP' })
  @Post('user/verify-registration')
  async verifyRegistration(@Body() data: VerifyRegistrationDto) {
    return await this.authService.verifyRegistration(data.nicNo, data.otp);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Resend Registration OTP' })
  @Post('user/resend-registration-otp')
  async resendRegistrationOtp(@Body() data: ResendRegistrationOtpDto) {
    return await this.authService.resendRegistrationOtp(data.nicNo);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Resend Password Reset OTP' })
  @Post('user/resend-reset-otp')
  async resendResetOtp(@Body() data: ResendResetOtpDto) {
    return await this.authService.resendResetOtp(data.nicNo, data.email);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Resend Device Verification OTP' })
  @Post('user/resend-device-otp')
  async resendDeviceOtp(@Body() data: ResendDeviceOtpDto) {
    return await this.authService.resendDeviceOtp(data.nicNo, data.email);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Login for Drivers' })
  @Post('user/login')
  async loginUser(@Body() data: UserLoginDto) {
    return await this.authService.loginUser(
      data.nicNo,
      data.password,
      data.deviceId,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Biometric Login for Drivers' })
  @Post('user/biometric-login')
  async biometricLogin(@Body() data: BiometricLoginDto) {
    return await this.authService.biometricLogin(data.nicNo, data.deviceId);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Verify new device with OTP' })
  @Post('user/verify-device')
  async verifyDevice(@Body() data: VerifyDeviceDto) {
    return await this.authService.verifyNewDevice(
      data.nicNo,
      data.deviceId,
      data.otp,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Step 1: Request OTP for password reset' })
  @Post('user/forgot-password-check')
  async forgotPasswordRequest(@Body() data: ForgotPasswordRequestDto) {
    return await this.authService.requestPasswordReset(data.nicNo, data.email);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Step 2: Verify OTP for password reset' })
  @Post('user/verify-reset-otp')
  async verifyUserResetOtp(@Body() data: VerifyResetOtpDto) {
    return await this.authService.verifyUserResetOtp(
      data.nicNo,
      data.email,
      data.otp,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Step 3: Reset Password with verified OTP' })
  @Post('user/reset-password')
  async resetPassword(@Body() data: ResetPasswordDto) {
    return await this.authService.resetPassword(
      data.nicNo,
      data.email,
      data.otp,
      data.newPassword,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Step 1: Request OTP for Divisional Head' })
  @Post('head/forgot-password-request')
  async headForgotPasswordRequest(@Body() data: HeadForgotPasswordRequestDto) {
    return await this.authService.requestHeadPasswordReset(
      data.username,
      data.email,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({
    summary: 'Step 2: Verify OTP for Divisional Head password reset',
  })
  @Post('head/verify-reset-otp')
  async headVerifyResetOtp(@Body() data: HeadVerifyResetOtpDto) {
    return await this.authService.verifyHeadResetOtp(
      data.username,
      data.email,
      data.otp,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Step 3: Reset Password for Divisional Head' })
  @Post('head/reset-password')
  async headResetPassword(@Body() data: HeadResetPasswordDto) {
    return await this.authService.resetHeadPassword(
      data.username,
      data.email,
      data.otp,
      data.newPasswordStr,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Resend OTP for Divisional Head' })
  @Post('head/resend-otp')
  async resendHeadOtp(
    @Body() data: ResendHeadOtpDto,
  ): Promise<{ message: string }> {
    return await this.authService.resendHeadOtp(data.username, data.email);
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Step 1: Request OTP for Traffic Officer' })
  @Post('officer/forgot-password-request')
  async officerForgotPasswordRequest(
    @Body() data: OfficerForgotPasswordRequestDto,
  ) {
    return await this.authService.requestOfficerPasswordReset(
      data.badgeNo,
      data.email,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({
    summary: 'Step 2: Verify OTP for Traffic Officer password reset',
  })
  @Post('officer/verify-reset-otp')
  async officerVerifyResetOtp(@Body() data: OfficerVerifyResetOtpDto) {
    return await this.authService.verifyOfficerResetOtp(
      data.badgeNo,
      data.email,
      data.otp,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Step 3: Reset Password for Traffic Officer' })
  @Post('officer/reset-password')
  async officerResetPassword(@Body() data: OfficerResetPasswordDto) {
    return await this.authService.resetOfficerPassword(
      data.badgeNo,
      data.email,
      data.otp,
      data.newPasswordStr,
    );
  }

  @SkipDeviceCheck()
  @ApiOperation({ summary: 'Resend OTP for Traffic Officer' })
  @Post('officer/resend-otp')
  async resendOfficerOtp(
    @Body() data: ResendOfficerOtpDto,
  ): Promise<{ message: string }> {
    return await this.authService.resendOfficerOtp(data.badgeNo, data.email);
  }

  @ApiBearerAuth()
  @ApiOperation({ summary: 'Change Password (DO or Officer)' })
  @UseGuards(JwtAuthGuard)
  @Patch('change-password')
  async changePassword(
    @Request() req: AuthRequest,
    @Body() changePasswordDto: ChangePasswordDto,
  ) {
    return this.authService.changePassword(
      req.user.id,
      req.user.role,
      changePasswordDto,
    );
  }

  @ApiBearerAuth()
  @ApiOperation({ summary: 'Change Password (User/Driver)' })
  @UseGuards(JwtAuthGuard)
  @Patch('user/change-password')
  async changeUserPassword(
    @Request() req: AuthRequest,
    @Body() changePasswordDto: ChangePasswordDto,
  ) {
    return this.authService.changeUserPassword(req.user.id, changePasswordDto);
  }
}
