import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';
import { ApiTags, ApiOperation, ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'HEAD-GALLE-01' })
  badgeNumber: string;

  @ApiProperty({ example: 'headpassword123' })
  password: string;
}

export class RegisterUserDto {
  @ApiProperty({ example: '200204802139' })
  nic: string;

  @ApiProperty({ example: 'K.V.V. Thishan' })
  name: string;

  @ApiProperty({ example: '0771234567' })
  phoneNumber: string;

  @ApiProperty({ example: 'driverpassword123' })
  password: string;

  @ApiProperty({ example: 'PHONE-MAC-001' })
  deviceId: string;
}

export class UserLoginDto {
  @ApiProperty({ example: '200204802139' })
  nic: string;

  @ApiProperty({ example: 'driverpassword123' })
  password: string;

  @ApiProperty({ example: 'PHONE-MAC-001' })
  deviceId: string;
}

export class VerifyDeviceDto {
  @ApiProperty({ example: '200204802139' })
  nic: string;

  @ApiProperty({ example: 'NEW-PHONE-MAC-002' })
  deviceId: string;
}

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @ApiOperation({ summary: 'Login for Officers and Heads' })
  @Post('login')
  async login(@Body() data: LoginDto) {
    return this.authService.login(data.badgeNumber, data.password);
  }

  @ApiOperation({ summary: 'Register a new driver' })
  @Post('user/register')
  async registerUser(@Body() data: RegisterUserDto) {
    return this.authService.registerUser(data);
  }

  @ApiOperation({ summary: 'Login for Drivers' })
  @Post('user/login')
  async loginUser(@Body() data: UserLoginDto) {
    return this.authService.loginUser(data.nic, data.password, data.deviceId);
  }

  @ApiOperation({ summary: 'Verify new device with OTP' })
  @Post('user/verify-device')
  async verifyDevice(@Body() data: VerifyDeviceDto) {
    return this.authService.verifyNewDevice(data.nic, data.deviceId);
  }
}
