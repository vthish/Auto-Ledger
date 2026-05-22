import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async registerUser(data: { nic: string; phoneNumber: string; name: string }) {
    return this.prisma.user.create({
      data,
    });
  }
}
