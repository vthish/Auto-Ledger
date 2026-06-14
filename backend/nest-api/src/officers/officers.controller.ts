import {
  Controller,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
  Get,
  Query,
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
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsOptional,
  IsEmail,
} from 'class-validator';

export class CreateDivisionDto {
  @ApiProperty() @IsString() @IsNotEmpty() divisionName: string;
}
export class CreateHeadDto {
  @ApiProperty() @IsString() @IsNotEmpty() divisionName: string;
  @ApiProperty() @IsString() @IsNotEmpty() username: string;
  @ApiProperty() @IsEmail() @IsNotEmpty() email: string;
  @ApiProperty() @IsString() @IsNotEmpty() name: string;
  @ApiProperty() @IsString() @IsNotEmpty() passwordStr: string;
}
export class CreateOfficerDto {
  @ApiProperty() @IsString() @IsNotEmpty() badgeNo: string;
  @ApiProperty() @IsEmail() @IsNotEmpty() email: string;
  @ApiProperty() @IsString() @IsNotEmpty() name: string;
  @ApiProperty() @IsString() @IsNotEmpty() passwordStr: string;
}
export class AssignShiftDto {
  @ApiProperty() @IsString() @IsNotEmpty() officerId: string;
  @ApiProperty() @IsDateString() date: Date;
  @ApiProperty() @IsDateString() startTime: Date;
  @ApiProperty() @IsDateString() endTime: Date;
  @ApiProperty() @IsString() location: string;
}
export class UpdateShiftDto {
  @ApiPropertyOptional() @IsDateString() @IsOptional() date?: Date;
  @ApiPropertyOptional() @IsDateString() @IsOptional() startTime?: Date;
  @ApiPropertyOptional() @IsDateString() @IsOptional() endTime?: Date;
  @ApiPropertyOptional() @IsString() @IsOptional() location?: string;
}

@ApiTags('Police Management')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('officers')
export class OfficersController {
  constructor(private readonly officersService: OfficersService) {}

  @Roles('POLICE_ADMIN')
  @Post('division')
  async createDivision(@Request() req: any, @Body() data: CreateDivisionDto) {
    return this.officersService.createDivision(data.divisionName, req.user.id);
  }

  @Roles('POLICE_ADMIN')
  @Post('head')
  async createDivisionalHead(@Body() data: CreateHeadDto) {
    return this.officersService.createDivisionalHead(data);
  }

  @Roles('DIVISIONAL_HEAD')
  @Post('officer')
  async createOfficer(@Request() req: any, @Body() data: CreateOfficerDto) {
    return this.officersService.createTrafficOfficer({
      ...data,
      headId: req.user.id,
    });
  }

  @Roles('DIVISIONAL_HEAD')
  @Post('shift')
  async assignShift(@Body() data: AssignShiftDto) {
    return this.officersService.assignShift(data);
  }

  @Roles('DIVISIONAL_HEAD')
  @Patch('shift/:id')
  async updateShift(
    @Param('id') id: string,
    @Body() updateShiftDto: UpdateShiftDto,
  ) {
    return this.officersService.updateShift(id, updateShiftDto);
  }

  @Roles('DIVISIONAL_HEAD')
  @Get('my-division')
  async getMyDivisionOfficers(
    @Request() req: any,
    @Query('search') search?: string,
  ) {
    return this.officersService.getDivisionOfficers(req.user.id, search);
  }

  @Roles('DIVISIONAL_HEAD')
  @Get(':id/shifts')
  async getOfficerShifts(@Param('id') id: string) {
    return this.officersService.getOfficerShifts(id);
  }
}
