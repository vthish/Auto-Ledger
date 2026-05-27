import { Controller, Post, Body, Get, UseGuards, Req } from '@nestjs/common';
import { Request } from 'express';
import { OfficersService } from './officers.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

interface AuthenticatedRequest extends Request {
  user: {
    id: string;
    role: string;
    districtId: string;
  };
}

@ApiTags('Officers')
@Controller('officers')
export class OfficersController {
  constructor(private readonly officersService: OfficersService) {}

  @ApiOperation({ summary: 'Register a Divisional Head' })
  @Post('register/head')
  async registerDivisionalHead(
    @Body()
    data: {
      badgeNumber: string;
      name: string;
      password: string;
      districtName: string;
    },
  ) {
    return this.officersService.registerDivisionalHead(data);
  }

  @ApiOperation({ summary: 'Register a new Traffic Officer' })
  @ApiBearerAuth()
  @Post('register')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async registerOfficer(
    @Req() req: AuthenticatedRequest,
    @Body()
    officerData: {
      badgeNumber: string;
      name: string;
      password: string;
      role?: string;
    },
  ) {
    const districtId = req.user.districtId;
    return this.officersService.registerOfficer({ ...officerData, districtId });
  }

  @ApiOperation({ summary: 'Assign a shift to an officer' })
  @ApiBearerAuth()
  @Post('shift')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async assignShift(
    @Body()
    data: {
      officerId: string;
      startTime: string;
      endTime: string;
    },
  ) {
    return this.officersService.assignShift(data);
  }

  @ApiOperation({ summary: 'Get all officers in the district' })
  @ApiBearerAuth()
  @Get('my-district')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async getMyDistrictOfficers(@Req() req: AuthenticatedRequest) {
    const districtId = req.user.districtId;
    return this.officersService.getOfficersByDistrict(districtId);
  }
}
