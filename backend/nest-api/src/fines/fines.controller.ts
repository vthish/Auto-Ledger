import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Patch,
  Delete,
  UseGuards,
  Request,
} from '@nestjs/common';
import {
  FinesService,
  CreateOffenseData,
  UpdateOffenseData,
} from './fines.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';

// Request එකට හරියට Type එකක් හදමු
export interface AuthRequest {
  user: { id: string; role?: string };
}

@ApiTags('Fines & Court Cases')
@ApiBearerAuth()
@Controller('fines')
export class FinesController {
  constructor(private readonly finesService: FinesService) {}

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('TRAFFIC_OFFICER')
  @Post()
  issueFine(
    @Request() req: AuthRequest,
    @Body() body: { licenseId: string; offenseIds: string[]; comment?: string },
  ) {
    return this.finesService.issueFine({
      licenseId: body.licenseId,
      officerId: req.user.id,
      offenseIds: body.offenseIds,
      comment: body.comment,
    });
  }

  @UseGuards(JwtAuthGuard)
  @Get('my-fines')
  getMyFines(@Request() req: AuthRequest) {
    return this.finesService.getMyFines(req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/pay')
  payFine(
    @Param('id') id: string,
    @Body() body: { amount: number; paymentMethod: string },
  ) {
    return this.finesService.payFine(id, body.amount, body.paymentMethod);
  }

  @UseGuards(JwtAuthGuard)
  @Post('pay-bulk')
  payBulkFines(
    @Body()
    body: {
      fineIds: string[];
      totalAmount: number;
      paymentMethod: string;
    },
  ) {
    return this.finesService.payBulkFines(
      body.fineIds,
      body.totalAmount,
      body.paymentMethod,
    );
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  @Patch(':id/court-verdict')
  updateCourtVerdict(
    @Param('id') id: string,
    @Body('verdict') verdict: 'ACTIVE' | 'REVOKED',
  ) {
    return this.finesService.updateCourtCase(id, verdict);
  }

  @Get('offenses')
  getAllOffenses() {
    return this.finesService.getAllOffenses();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('POLICE_ADMIN')
  @Post('offenses')
  createOffense(@Request() req: AuthRequest, @Body() body: CreateOffenseData) {
    return this.finesService.createOffenseCategory(body, req.user.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('POLICE_ADMIN')
  @Patch('offenses/:id')
  updateOffense(@Param('id') id: string, @Body() body: UpdateOffenseData) {
    return this.finesService.updateOffenseCategory(id, body);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('POLICE_ADMIN')
  @Delete('offenses/:id')
  deleteOffense(@Param('id') id: string) {
    return this.finesService.deleteOffenseCategory(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  @Get('court-cases')
  getCourtCases(@Request() req: AuthRequest) {
    return this.finesService.getCourtCasesByDH(req.user.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  @Get('dashboard-stats')
  getDashboardStats(@Request() req: AuthRequest) {
    return this.finesService.getDashboardStats(req.user.id);
  }
}
