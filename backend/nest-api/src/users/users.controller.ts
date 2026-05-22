import { Controller, Post, Body } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}
  @Post('register')
  async register(
    @Body() userData: { nic: string; phoneNumber: string; name: string },
  ) {
    return this.usersService.registerUser(userData);
  }
}
