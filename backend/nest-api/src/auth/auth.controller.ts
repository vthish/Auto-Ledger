import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  async login(@Body() data: { badgeNumber: string; password: string }) {
    return this.authService.login(data.badgeNumber, data.password);
  }
}
