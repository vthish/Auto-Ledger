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
  IsEmail,
} from 'class-validator';

export class CreateDivisionDto {
  @IsString()
  @IsNotEmpty()
  divisionName: string;
}

export class CreateHeadDto {
  @IsString()
  @IsNotEmpty()
  divisionName: string;

  @IsString()
  @IsNotEmpty()
  username: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  passwordStr: string;
}

export class CreateOfficerDto {
  @IsString()
  @IsNotEmpty()
  badgeNo: string;

  @IsEmail()
  @IsNotEmpty()
  email: string;

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

  @ApiOperation({ summary: 'Create Division (Police Admin)' })
  @Post('division')
  async createDivision(
    @Request() req: OfficerAuthRequest,
    @Body() data: CreateDivisionDto,
  ) {
    return this.officersService.createDivision(data.divisionName, req.user.sub);
  }

  @ApiOperation({
    summary: 'Assign Divisional Head to Division (Police Admin)',
  })
  @Post('head')
  async createDivisionalHead(@Body() data: CreateHeadDto) {
    return this.officersService.createDivisionalHead({
      divisionName: data.divisionName,
      username: data.username,
      email: data.email,
      name: data.name,
      passwordStr: data.passwordStr,
    });
  }

  @ApiOperation({ summary: 'Create Traffic Officer (Divisional Head Only)' })
  @Post('officer')
  async createOfficer(
    @Request() req: OfficerAuthRequest,
    @Body() data: CreateOfficerDto,
  ) {
    return this.officersService.createTrafficOfficer({
      badgeNo: data.badgeNo,
      email: data.email,
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
