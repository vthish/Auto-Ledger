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
import {
  IsString,
  MinLength,
  Matches,
  IsEnum,
  IsNotEmpty,
} from 'class-validator';

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
  nicNo: string;

  @ApiProperty({ example: 'K.V.V. Thishan' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: '+94771234567' })
  @IsString()
  @IsNotEmpty()
  mobilePhoneNo: string;

  @ApiProperty({ example: 'Driver@Pass123!' })
  @IsString()
  @MinLength(8)
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
  )
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
  nicNo: string;
}

export class UserLoginDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
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
  nicNo: string;

  @ApiProperty({ example: 'NEW-PHONE-MAC-002' })
  @IsString()
  @IsNotEmpty()
  deviceId: string;
}

export class ChangePasswordDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  oldPassword: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  newPassword: string;
}

export class BiometricLoginDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
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
  nicNo: string;

  @ApiProperty({ example: '+94771234567' })
  @IsString()
  @IsNotEmpty()
  mobilePhoneNo: string;
}

export class ResetPasswordDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  nicNo: string;

  @ApiProperty({ example: '+94771234567' })
  @IsString()
  @IsNotEmpty()
  mobilePhoneNo: string;

  @ApiProperty({ example: 'NewDriver@Pass123!' })
  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  newPassword: string;
}

export interface AuthRequest {
  user: {
    id: string;
    sub: string;
    role: string;
  };
}

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @ApiOperation({ summary: 'Login for DMT & Police Admins' })
  @Post('admin/login')
  async loginAdmin(@Body() data: AdminLoginDto) {
    return await this.authService.loginAdmin(
      data.username,
      data.password,
      data.type,
    );
  }

  @ApiOperation({ summary: 'Login for Divisional Heads' })
  @Post('head/login')
  async loginHead(@Body() data: HeadLoginDto) {
    return await this.authService.loginHead(data.username, data.password);
  }

  @ApiOperation({ summary: 'Login for Traffic Officers' })
  @Post('officer/login')
  async loginOfficer(@Body() data: OfficerLoginDto) {
    return await this.authService.loginOfficer(data.badgeNo, data.password);
  }

  @ApiOperation({ summary: 'Step 1: Register a new driver' })
  @Post('user/register')
  async registerUser(@Body() data: RegisterUserDto) {
    return await this.authService.registerUser(data);
  }

  @ApiOperation({ summary: 'Step 2: Complete Registration' })
  @Post('user/verify-registration')
  async verifyRegistration(@Body() data: VerifyRegistrationDto) {
    return await this.authService.verifyRegistration(data.nicNo);
  }

  @ApiOperation({ summary: 'Login for Drivers' })
  @Post('user/login')
  async loginUser(@Body() data: UserLoginDto) {
    return await this.authService.loginUser(
      data.nicNo,
      data.password,
      data.deviceId,
    );
  }

  @ApiOperation({ summary: 'Biometric Login for Drivers' })
  @Post('user/biometric-login')
  async biometricLogin(@Body() data: BiometricLoginDto) {
    return await this.authService.biometricLogin(data.nicNo, data.deviceId);
  }

  @ApiOperation({ summary: 'Verify new device with OTP' })
  @Post('user/verify-device')
  async verifyDevice(@Body() data: VerifyDeviceDto) {
    return await this.authService.verifyNewDevice(data.nicNo, data.deviceId);
  }

  @ApiOperation({ summary: 'Step 1: Check NIC & Phone' })
  @Post('user/forgot-password-check')
  async forgotPasswordRequest(@Body() data: ForgotPasswordRequestDto) {
    return await this.authService.requestPasswordReset(
      data.nicNo,
      data.mobilePhoneNo,
    );
  }

  @ApiOperation({ summary: 'Step 2: Reset Password' })
  @Post('user/reset-password')
  async resetPassword(@Body() data: ResetPasswordDto) {
    return await this.authService.resetPassword(
      data.nicNo,
      data.mobilePhoneNo,
      data.newPassword,
    );
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
      req.user.sub,
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
    return this.authService.changeUserPassword(req.user.sub, changePasswordDto);
  }
}
