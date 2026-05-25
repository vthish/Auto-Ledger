import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async registerUser(data: {
    nic: string;
    phoneNumber: string;
    name: string;
    password: string;
  }) {
    return this.prisma.user.create({
      data: {
        nic: data.nic,
        phoneNumber: data.phoneNumber,
        name: data.name,
        password: data.password,
      },
    });
  }

  async getUserById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  async updateUser(id: string, data: { name?: string; phoneNumber?: string }) {
    return this.prisma.user.update({
      where: { id },
      data,
    });
  }

  async deleteUser(id: string) {
    return this.prisma.user.delete({
      where: { id },
    });
  }
}
