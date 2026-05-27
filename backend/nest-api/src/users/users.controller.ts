import {
  Controller,
  Get,
  Param,
  Patch,
  Body,
  Delete,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @ApiOperation({ summary: 'Get user by ID' })
  @Get(':id')
  async getUserById(@Param('id') id: string) {
    return this.usersService.getUserById(id);
  }

  @ApiOperation({ summary: 'Update user details' })
  @Patch(':id')
  async updateUser(
    @Param('id') id: string,
    @Body() data: { name?: string; phoneNumber?: string },
  ) {
    return this.usersService.updateUser(id, data);
  }

  @ApiOperation({ summary: 'Delete a user' })
  @Delete(':id')
  async deleteUser(@Param('id') id: string) {
    return this.usersService.deleteUser(id);
  }
}
