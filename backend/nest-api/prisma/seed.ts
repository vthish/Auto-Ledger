import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const dmtPlainPassword = 'DmtAdmin@Password123!';
  const policePlainPassword = 'PoliceAdmin@Password123!';
  const saltRounds = 10;

  const hashedDmtPassword = await bcrypt.hash(dmtPlainPassword, saltRounds);
  const hashedPolicePassword = await bcrypt.hash(
    policePlainPassword,
    saltRounds,
  );

  await prisma.dMT_Admin.upsert({
    where: { username: 'maindmt' },
    update: {},
    create: {
      username: 'maindmt',
      name: 'Main DMT Admin',
      password: hashedDmtPassword,
    },
  });

  await prisma.police_Admin.upsert({
    where: { username: 'mainpolice' },
    update: {},
    create: {
      username: 'mainpolice',
      name: 'Main Police Admin',
      password: hashedPolicePassword,
    },
  });
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
