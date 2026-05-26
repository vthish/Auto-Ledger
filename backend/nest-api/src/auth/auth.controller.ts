import { Controller, Post, Body } from '@nestjs/common';
import { AuthService, RegisterUserDto } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  async login(@Body() data: { badgeNumber: string; password: string }) {
    return this.authService.login(data.badgeNumber, data.password);
  }

  @Post('user/register')
  async registerUser(@Body() data: RegisterUserDto) {
    return this.authService.registerUser(data);
  }

  @Post('user/login')
  async loginUser(
    @Body() data: { nic: string; password: string; deviceId: string },
  ) {
    return this.authService.loginUser(data.nic, data.password, data.deviceId);
  }

  @Post('user/verify-device')
  async verifyDevice(@Body() data: { nic: string; deviceId: string }) {
    return this.authService.verifyNewDevice(data.nic, data.deviceId);
  }
}
