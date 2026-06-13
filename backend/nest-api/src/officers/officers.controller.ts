import {
  Controller,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { OfficersService } from './officers.service';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiPropertyOptional,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsOptional,
} from 'class-validator';

export class CreateDivisionWithHeadDto {
  @IsString()
  @IsNotEmpty()
  divisionName: string;

  @IsString()
  @IsNotEmpty()
  headUsername: string;

  @IsString()
  @IsNotEmpty()
  headName: string;

  @IsString()
  @IsNotEmpty()
  headPasswordStr: string;
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

export class UpdateShiftDto {
  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  date?: Date;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  startTime?: Date;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  endTime?: Date;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  location?: string;
}

export interface OfficerAuthRequest {
  user: {
    id: string;
    sub: string;
    role: string;
  };
}

@ApiTags('Police Management')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('officers')
export class OfficersController {
  constructor(private readonly officersService: OfficersService) {}

  @ApiOperation({ summary: 'Create Division & Divisional Head (Police Admin)' })
  @Post('division-and-head')
  async createDivisionWithHead(
    @Request() req: OfficerAuthRequest,
    @Body() data: CreateDivisionWithHeadDto,
  ) {
    return this.officersService.createDivisionWithHead(
      data.divisionName,
      req.user.sub,
      data.headUsername,
      data.headName,
      data.headPasswordStr,
    );
  }

  @ApiOperation({ summary: 'Create Traffic Officer (Divisional Head Only)' })
  @Post('officer')
  async createOfficer(
    @Request() req: OfficerAuthRequest,
    @Body() data: CreateOfficerDto,
  ) {
    return this.officersService.createTrafficOfficer({
      badgeNo: data.badgeNo,
      name: data.name,
      passwordStr: data.passwordStr,
      headId: req.user.sub,
    });
  }

  @ApiOperation({ summary: 'Assign Shift to Officer' })
  @Post('shift')
  async assignShift(@Body() data: AssignShiftDto) {
    return this.officersService.assignShift(data);
  }

  @ApiOperation({ summary: 'Update an existing shift' })
  @Patch('shift/:id')
  async updateShift(
    @Param('id') id: string,
    @Body() updateShiftDto: UpdateShiftDto,
  ) {
    return this.officersService.updateShift(id, updateShiftDto);
  }
}
