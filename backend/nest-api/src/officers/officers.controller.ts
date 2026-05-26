import { Controller, Post, Body, Get, UseGuards, Req } from '@nestjs/common';
import { Request } from 'express';
import { OfficersService } from './officers.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

interface AuthenticatedRequest extends Request {
  user: {
    id: string;
    role: string;
    districtId: string;
  };
}

@Controller('officers')
export class OfficersController {
  constructor(private readonly officersService: OfficersService) {}

  // Open endpoint to register heads (Usually done via DB seed or Super Admin)
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

  // Restricted to DIVISIONAL_HEAD
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
    // Automatically assign the officer to the Head's district
    const districtId = req.user.districtId;
    return this.officersService.registerOfficer({ ...officerData, districtId });
  }

  // Restricted to DIVISIONAL_HEAD
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

  // Restricted to DIVISIONAL_HEAD to view their own district's officers
  @Get('my-district')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async getMyDistrictOfficers(@Req() req: AuthenticatedRequest) {
    const districtId = req.user.districtId;
    return this.officersService.getOfficersByDistrict(districtId);
  }
}
