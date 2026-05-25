import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log(
    'Seeding predefined offenses from the Sri Lankan traffic fine sheet...',
  );

  const offenses = [
    {
      code: '01',
      name: 'වේගයෙන් පැදවීම (Speeding)',
      amount: 1000,
      points: 2,
      isCourtCase: false,
    },
    {
      code: '02',
      name: 'නැවැත්වීම හෝ නවතා තැබීම (Parking)',
      amount: 500,
      points: 1,
      isCourtCase: false,
    },
    {
      code: '03',
      name: 'සංඥා සහ පොලිස් නිලධාරීන්ගේ විධාන (Signals/directions of Police Officer)',
      amount: 1000,
      points: 2,
      isCourtCase: false,
    },
    {
      code: '04',
      name: 'බලපත්‍ර නොමැතිව පැදවීම (Without D.L.)',
      amount: 2500,
      points: 4,
      isCourtCase: true,
    },
    {
      code: '05',
      name: 'අවු. 18ට අඩු අය රිය පැදවීම (Driving under 18 years of age)',
      amount: 5000,
      points: 5,
      isCourtCase: true,
    },
    {
      code: '06',
      name: 'බලපත්‍ර නොමැති අයෙකු සේවයේ යෙදවීම (Employing person without D.L.)',
      amount: 3000,
      points: 3,
      isCourtCase: true,
    },
    {
      code: '07',
      name: 'ආදායම් බලපත්‍ර රැගෙන නොයෑම (R. L. not carried)',
      amount: 500,
      points: 1,
      isCourtCase: false,
    },
    {
      code: '08',
      name: 'බලපත්‍ර කොන්දේසි උල්ලංඝනය කිරීම (Contravening R. L. restrictions)',
      amount: 1000,
      points: 2,
      isCourtCase: false,
    },
    {
      code: '22',
      name: 'ආරක්ෂක හිස් වැසුම් නොපැළඳීම (Not wearing protective helmet)',
      amount: 500,
      points: 1,
      isCourtCase: false,
    },
    {
      code: '23-1',
      name: 'වමෙන් නොපැදවීම (Failing to keep to left of road)',
      amount: 500,
      points: 1,
      isCourtCase: false,
    },
    {
      code: '23-4',
      name: 'බාධක මැද ඉස්සර කිරීම (Overtaking without clear view)',
      amount: 500,
      points: 2,
      isCourtCase: false,
    },
    {
      code: '99',
      name: 'බීමත්ව රිය පැදවීම (DUI / Intoxicated Operation)',
      amount: 0,
      points: 10,
      isCourtCase: true,
    },
  ];

  for (const offense of offenses) {
    await prisma.offenseCategory.upsert({
      where: { code: offense.code },
      update: offense,
      create: offense,
    });
  }

  console.log('Seeding districts and divisional heads...');

  const galleDistrict = await prisma.district.upsert({
    where: { name: 'Galle' },
    update: {},
    create: {
      id: 'district-galle',
      name: 'Galle',
    },
  });

  await prisma.officer.upsert({
    where: { badgeNumber: 'HEAD-GALLE-01' },
    update: {},
    create: {
      badgeNumber: 'HEAD-GALLE-01',
      name: 'Saman Kumara',
      password: 'headpassword123',
      role: 'DIVISIONAL_HEAD',
      districtId: galleDistrict.id,
    },
  });

  const mataraDistrict = await prisma.district.upsert({
    where: { name: 'Matara' },
    update: {},
    create: {
      id: 'district-matara',
      name: 'Matara',
    },
  });

  await prisma.officer.upsert({
    where: { badgeNumber: 'HEAD-MATARA-01' },
    update: {},
    create: {
      badgeNumber: 'HEAD-MATARA-01',
      name: 'Nimal Silva',
      password: 'headpassword456',
      role: 'DIVISIONAL_HEAD',
      districtId: mataraDistrict.id,
    },
  });

  console.log('Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
