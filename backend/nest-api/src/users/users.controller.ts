import {
  Controller,
  Get,
  Patch,
  Body,
  Request,
  UseGuards,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { IsString, IsNotEmpty } from 'class-validator';

export class UpdateDeviceDto {
  @IsString()
  @IsNotEmpty()
  deviceId: string;
}

@ApiTags('Users (Drivers)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @ApiOperation({ summary: 'Get current logged-in user profile' })
  @Get('profile')
  async getProfile(@Request() req) {
    return this.usersService.getUserById(req.user.id);
  }

  @ApiOperation({ summary: 'Update driver device ID' })
  @Patch('device')
  async updateDevice(@Request() req, @Body() data: UpdateDeviceDto) {
    return this.usersService.updateUserDevice(req.user.id, data.deviceId);
  }

  @ApiOperation({ summary: 'Verify Phone Number' })
  @Patch('verify-phone')
  async verifyPhone(@Request() req) {
    return this.usersService.verifyPhone(req.user.id);
  }
}
