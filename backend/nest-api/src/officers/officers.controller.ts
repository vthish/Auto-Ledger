import {
  Controller,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
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

@ApiTags('Police Management')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('officers')
export class OfficersController {
  constructor(private readonly officersService: OfficersService) {}

  @ApiOperation({ summary: 'Create Divisional Head' })
  @Post('head')
  async createHead(@Body() data: CreateHeadDto) {
    return this.officersService.createDivisionalHead(data);
  }

  @ApiOperation({ summary: 'Create Traffic Officer' })
  @Post('officer')
  async createOfficer(@Body() data: CreateOfficerDto) {
    return this.officersService.createTrafficOfficer(data);
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
