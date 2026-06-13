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
  ApiProperty,
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
  @ApiProperty({ example: 'Galle Division' })
  @IsString()
  @IsNotEmpty()
  divisionName: string;
}

export class CreateHeadDto {
  @ApiProperty({ example: 'Galle Division' })
  @IsString()
  @IsNotEmpty()
  divisionName: string;

  @ApiProperty({ example: 'kamal_do' })
  @IsString()
  @IsNotEmpty()
  username: string;

  @ApiProperty({ example: 'kamal@police.lk' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'Kamal Perera' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'Head@Pass123!' })
  @IsString()
  @IsNotEmpty()
  passwordStr: string;
}

export class CreateOfficerDto {
  @ApiProperty({ example: 'TRF-GALLE-001' })
  @IsString()
  @IsNotEmpty()
  badgeNo: string;

  @ApiProperty({ example: 'nimal@police.lk' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'Nimal Siripala' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'Officer@Pass123!' })
  @IsString()
  @IsNotEmpty()
  passwordStr: string;
}

export class AssignShiftDto {
  @ApiProperty({ example: 'Officer_UUID_Here' })
  @IsString()
  @IsNotEmpty()
  officerId: string;

  @ApiProperty({ example: '2026-06-13' })
  @IsDateString()
  date: Date;

  @ApiProperty({ example: '2026-06-13T06:00:00Z' })
  @IsDateString()
  startTime: Date;

  @ApiProperty({ example: '2026-06-13T14:00:00Z' })
  @IsDateString()
  endTime: Date;

  @ApiProperty({ example: 'Galle Town' })
  @IsString()
  location: string;
}

export class UpdateShiftDto {
  @ApiPropertyOptional({ example: '2026-06-14' })
  @IsDateString()
  @IsOptional()
  date?: Date;

  @ApiPropertyOptional({ example: '2026-06-14T06:00:00Z' })
  @IsDateString()
  @IsOptional()
  startTime?: Date;

  @ApiPropertyOptional({ example: '2026-06-14T14:00:00Z' })
  @IsDateString()
  @IsOptional()
  endTime?: Date;

  @ApiPropertyOptional({ example: 'Colombo' })
  @IsString()
  @IsOptional()
  location?: string;
}

export interface OfficerAuthRequest {
  user: {
    id: string;
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
    // req.user.sub වෙනුවට req.user.id දැම්මා
    return this.officersService.createDivision(data.divisionName, req.user.id);
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
      // req.user.sub වෙනුවට req.user.id දැම්මා
      headId: req.user.id,
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
