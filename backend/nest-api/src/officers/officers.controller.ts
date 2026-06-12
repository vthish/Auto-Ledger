import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { OfficersService } from './officers.service';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { IsString, IsNotEmpty, IsDateString } from 'class-validator';

export class CreateHeadDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  divisionId: string;

  @IsString()
  @IsNotEmpty()
  passwordStr: string;
}

export class CreateOfficerDto {
  @IsString()
  @IsNotEmpty()
  badgeNo: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  headId: string;

  @IsString()
  @IsNotEmpty()
  passwordStr: string;
}

export class AssignShiftDto {
  @IsString()
  @IsNotEmpty()
  officerId: string;

  @IsDateString()
  date: Date;

  @IsDateString()
  startTime: Date;

  @IsDateString()
  endTime: Date;

  @IsString()
  location: string;
}

@ApiTags('Police Management')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('officers')
export class OfficersController {
  constructor(private readonly officersService: OfficersService) {}

  @ApiOperation({ summary: 'Create Divisional Head (Police Admin Only)' })
  @Post('head')
  async createHead(@Body() data: CreateHeadDto) {
    return this.officersService.createDivisionalHead(data);
  }

  @ApiOperation({ summary: 'Create Traffic Officer (Divisional Head Only)' })
  @Post('officer')
  async createOfficer(@Body() data: CreateOfficerDto) {
    return this.officersService.createTrafficOfficer(data);
  }

  @ApiOperation({ summary: 'Assign Shift to Officer' })
  @Post('shift')
  async assignShift(@Body() data: AssignShiftDto) {
    return this.officersService.assignShift(data);
  }
}
