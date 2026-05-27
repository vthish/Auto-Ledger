import { Controller, Post, Body, Get, UseGuards, Req } from '@nestjs/common';
import { Request } from 'express';
import { OfficersService } from './officers.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiProperty,
} from '@nestjs/swagger';

export class RegisterHeadDto {
  @ApiProperty({ example: 'HEAD-GALLE-01' })
  badgeNumber: string;

  @ApiProperty({ example: 'Kamal Perera' })
  name: string;

  @ApiProperty({ example: 'headpassword123' })
  password: string;

  @ApiProperty({ example: 'Galle' })
  districtName: string;
}

export class RegisterOfficerDto {
  @ApiProperty({ example: 'TRF-GALLE-100' })
  badgeNumber: string;

  @ApiProperty({ example: 'Nimal Silva' })
  name: string;

  @ApiProperty({ example: 'officerpassword123' })
  password: string;

  @ApiProperty({ example: 'TRAFFIC_OFFICER', required: false })
  role?: string;
}

export class AssignShiftDto {
  @ApiProperty({ example: 'officer-uuid-here' })
  officerId: string;

  @ApiProperty({ example: '2026-05-28T08:00:00Z' })
  startTime: string;

  @ApiProperty({ example: '2026-05-28T16:00:00Z' })
  endTime: string;
}

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
  async registerDivisionalHead(@Body() data: RegisterHeadDto) {
    return this.officersService.registerDivisionalHead(data);
  }

  @ApiOperation({ summary: 'Register a new Traffic Officer' })
  @ApiBearerAuth()
  @Post('register')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async registerOfficer(
    @Req() req: AuthenticatedRequest,
    @Body() officerData: RegisterOfficerDto,
  ) {
    const districtId = req.user.districtId;
    return this.officersService.registerOfficer({ ...officerData, districtId });
  }

  @ApiOperation({ summary: 'Assign a shift to an officer' })
  @ApiBearerAuth()
  @Post('shift')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async assignShift(@Body() data: AssignShiftDto) {
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
