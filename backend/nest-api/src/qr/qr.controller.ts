import {
  Controller,
  Post,
  Body,
  Param,
  Get,
  UseGuards,
  Request,
} from '@nestjs/common';
import { QrService } from './qr.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

export interface AuthRequest {
  user: { id: string; role?: string };
}

@Controller('qr')
export class QrController {
  constructor(private readonly qrService: QrService) {}

  @Post('generate')
  async generateQr(@Body('userId') userId: string) {
    return this.qrService.generateQrSession(userId);
  }

  @Get('status/:sessionId')
  async getQrStatus(@Param('sessionId') sessionId: string): Promise<{
    status: string;
    expiresAt: Date | null;
    scanned: boolean;
  }> {
    return await this.qrService.getQrStatus(sessionId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('TRAFFIC_OFFICER')
  @Post('scan/:sessionId')
  async scanQrCode(
    @Param('sessionId') sessionId: string,
    @Request() req: AuthRequest,
  ) {
    return this.qrService.scanQr(sessionId, req.user.id);
  }
}
