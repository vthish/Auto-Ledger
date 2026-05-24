import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log(
    'Seeding predefined offenses from the Sri Lankan traffic fine sheet...',
  );

  const offenses = [
    { code: '01', name: 'වේගයෙන් පැදවීම (Speeding)', amount: 1000, points: 2 },
    {
      code: '02',
      name: 'නැවැත්වීම හෝ නවතා තැබීම (Parking)',
      amount: 500,
      points: 1,
    },
    {
      code: '03',
      name: 'සංඥා සහ පොලිස් නිලධාරීන්ගේ විධාන (Signals/directions of Police Officer)',
      amount: 1000,
      points: 2,
    },
    {
      code: '04',
      name: 'බලපත්‍ර නොමැතිව පැදවීම (Without D.L.)',
      amount: 2500,
      points: 4,
    },
    {
      code: '05',
      name: 'අවු. 18ට අඩු අය රිය පැදවීම (Driving under 18 years of age)',
      amount: 5000,
      points: 5,
    },
    {
      code: '06',
      name: 'බලපත්‍ර නොමැති අයෙකු සේවයේ යෙදවීම (Employing person without D.L.)',
      amount: 3000,
      points: 3,
    },
    {
      code: '07',
      name: 'ආදායම් බලපත්‍ර රැගෙන නොයෑම (R. L. not carried)',
      amount: 500,
      points: 1,
    },
    {
      code: '08',
      name: 'බලපත්‍ර කොන්දේසි උල්ලංඝනය කිරීම (Contravening R. L. restrictions)',
      amount: 1000,
      points: 2,
    },
    {
      code: '22',
      name: 'ආරක්ෂක හිස් වැසුම් නොපැළඳීම (Not wearing protective helmet)',
      amount: 500,
      points: 1,
    },
    {
      code: '23-1',
      name: 'වමෙන් නොපැදවීම (Failing to keep to left of road)',
      amount: 500,
      points: 1,
    },
    {
      code: '23-4',
      name: 'බාධක මැද ඉස්සර කිරීම (Overtaking without clear view)',
      amount: 500,
      points: 2,
    },
  ];

  for (const offense of offenses) {
    await prisma.offenseCategory.upsert({
      where: { code: offense.code },
      update: {},
      create: offense,
    });
  }

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
