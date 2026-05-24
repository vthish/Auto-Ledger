import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  // Register a new user with strictly defined fields from the schema
  async registerUser(data: { nic: string; phoneNumber: string; name: string }) {
    return this.prisma.user.create({
      data: {
        nic: data.nic,
        phoneNumber: data.phoneNumber,
        name: data.name,
      },
    });
  }

  // Retrieve user details by their unique ID
  async getUserById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
    });
  }

  // Update user details like name or phone number
  async updateUser(id: string, data: { name?: string; phoneNumber?: string }) {
    return this.prisma.user.update({
      where: { id },
      data,
    });
  }

  // Delete a user from the system
  async deleteUser(id: string) {
    return this.prisma.user.delete({
      where: { id },
    });
  }
}
