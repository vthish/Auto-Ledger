import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Patch,
  Delete,
} from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // POST endpoint to register a new driver
  @Post('register')
  async registerUser(
    @Body() userData: { nic: string; phoneNumber: string; name: string },
  ) {
    return this.usersService.registerUser(userData);
  }

  // GET endpoint to fetch user details
  @Get(':id')
  async getUser(@Param('id') id: string) {
    return this.usersService.getUserById(id);
  }

  // PATCH endpoint to update user information
  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateData: { name?: string; phoneNumber?: string },
  ) {
    return this.usersService.updateUser(id, updateData);
  }

  // DELETE endpoint to remove a user
  @Delete(':id')
  async remove(@Param('id') id: string) {
    return this.usersService.deleteUser(id);
  }
}
