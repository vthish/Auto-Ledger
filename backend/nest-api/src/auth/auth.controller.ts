import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';
import { ApiTags, ApiOperation, ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  MinLength,
  Matches,
  IsEnum,
  IsNotEmpty,
} from 'class-validator';

export class AdminLoginDto {
  @ApiProperty({ example: 'admin-uuid-here' })
  @IsString()
  @IsNotEmpty()
  adminId: string;

  @ApiProperty({ example: 'DmtAdmin@Password123!' })
  @IsString()
  @IsNotEmpty()
  password: string;

  @ApiProperty({ example: 'DMT', enum: ['DMT', 'POLICE'] })
  @IsEnum(['DMT', 'POLICE'])
  type: 'DMT' | 'POLICE';
}

export class HeadLoginDto {
  @ApiProperty({ example: 'head-uuid-here' })
  @IsString()
  @IsNotEmpty()
  headId: string;

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
  nicNo: string;

  @ApiProperty({ example: 'K.V.V. Thishan' })
  @IsString()
  name: string;

  @ApiProperty({ example: '0771234567' })
  @IsString()
  mobilePhoneNo: string;

  @ApiProperty({ example: 'Driver@Pass123!' })
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long.' })
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    {
      message:
        'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.',
    },
  )
  password: string;

  @ApiProperty({ example: 'PHONE-MAC-001' })
  @IsString()
  deviceId: string;
}

export class UserLoginDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  nicNo: string;

  @ApiProperty({ example: 'Driver@Pass123!' })
  @IsString()
  password: string;

  @ApiProperty({ example: 'PHONE-MAC-001' })
  @IsString()
  deviceId: string;
}

export class VerifyDeviceDto {
  @ApiProperty({ example: '200204802139' })
  @IsString()
  nicNo: string;

  @ApiProperty({ example: 'NEW-PHONE-MAC-002' })
  @IsString()
  deviceId: string;
}

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @ApiOperation({ summary: 'Login for DMT & Police Admins (Web Portal)' })
  @Post('admin/login')
  async loginAdmin(@Body() data: AdminLoginDto) {
    return await this.authService.loginAdmin(
      data.adminId,
      data.password,
      data.type,
    );
  }

  @ApiOperation({ summary: 'Login for Divisional Heads' })
  @Post('head/login')
  async loginHead(@Body() data: HeadLoginDto) {
    return await this.authService.loginHead(data.headId, data.password);
  }

  @ApiOperation({ summary: 'Login for Traffic Officers' })
  @Post('officer/login')
  async loginOfficer(@Body() data: OfficerLoginDto) {
    return await this.authService.loginOfficer(data.badgeNo, data.password);
  }

  @ApiOperation({ summary: 'Register a new driver' })
  @Post('user/register')
  async registerUser(@Body() data: RegisterUserDto) {
    return await this.authService.registerUser(data);
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

  @ApiOperation({ summary: 'Verify new device with OTP' })
  @Post('user/verify-device')
  async verifyDevice(@Body() data: VerifyDeviceDto) {
    return await this.authService.verifyNewDevice(data.nicNo, data.deviceId);
  }
}
