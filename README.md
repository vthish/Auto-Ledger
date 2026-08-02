<div align="center">

# 🚦 Auto Ledger

### Digital Driving Licence, Traffic Fine & Penalty-Points Management Platform

[![Project](https://img.shields.io/badge/Project-Full--Stack%20Monorepo-0A66C2?style=for-the-badge)](#overview)
[![Owner](https://img.shields.io/badge/Owner-Venusha_Thishan-7C3AED?style=for-the-badge)](#team)
[![Backend](https://img.shields.io/badge/Backend-NestJS%2011-E0234E?style=for-the-badge&logo=nestjs&logoColor=white)](#technology-stack)
[![Mobile](https://img.shields.io/badge/Mobile-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](#technology-stack)
[![Web](https://img.shields.io/badge/Web-Next.js%2016-000000?style=for-the-badge&logo=nextdotjs&logoColor=white)](#technology-stack)
[![Cloud](https://img.shields.io/badge/Cloud-AWS-FF9900?style=for-the-badge&logo=amazonwebservices&logoColor=white)](#deployment)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitLab-FC6D26?style=for-the-badge&logo=gitlab&logoColor=white)](#deployment)
[![Licence](https://img.shields.io/badge/Licence-MIT-2EA44F?style=for-the-badge)](LICENSE)

A secure multi-role platform for digital driving licences, QR-based roadside verification, traffic fines, penalty points, temporary licences, court cases and police administration.

### 🌐 [Open Production Admin Portal](https://www.auto-ledger.tech)

**Owner & Core Contributor:** Venusha Thishan

</div>

---

<div align="center">

[Overview](#overview) • [Features](#core-features) • [Workflows](#how-it-works) • [Architecture](#architecture) • [Setup](#local-development) • [Deployment](#deployment) • [API Reference](#technical-reference) • [Team](#team)

</div>

---

<a id="at-a-glance"></a>
## ✨ At a Glance

| | |
|---|---|
| **5 application roles** | Driver, Traffic Officer, Divisional Head, Police Admin and DMT Admin |
| **3 client applications** | Two Flutter apps and one Next.js admin portal |
| **QR-first enforcement** | Fine issuance requires a valid short-lived QR connection |
| **Cloud deployment** | AWS EC2, AWS Amplify and Amazon S3 |
| **Secure access** | JWT, OTP, device binding, active-shift checks and mobile biometrics |
| **Monorepo workflow** | GitLab source control and CI/CD deployment |

---

<a id="overview"></a>
## 🚀 Overview

Auto Ledger is a full-stack monorepo created to digitise the driving-licence and traffic-fine lifecycle. It connects five system roles through two Flutter mobile applications, one Next.js administrative portal, and a NestJS REST API backed by PostgreSQL.

The platform is designed around a secure QR-first enforcement process. A Traffic Officer cannot issue a fine directly from a licence number alone. The Driver first creates a QR session, the authorised Traffic Officer scans it during an active shift, and the backend establishes a short-lived connection to the Driver and licence before fine issuance is permitted.

### Platform Components

| Component | Purpose | Deployment |
|---|---|---|
| Driver Mobile App | Digital licence, QR, points, fines, payments, receipts, profile and security | Flutter Android/iOS build |
| Police Mobile App | Traffic Officer and Divisional Head operational workflows | Flutter Android/iOS build |
| Admin Web Portal | DMT Admin and Police Admin management dashboards | AWS Amplify Hosting |
| Backend API | Authentication, licence, QR, fine, payment, officer and reporting services | Docker on AWS EC2 |
| PostgreSQL | Relational system of record | Configured through `DATABASE_URL` |
| Amazon S3 | Driving-licence image storage | Accessed by the backend through AWS IAM permissions |
| GitLab | Source control, merge requests, releases and CI/CD | GitLab repository and runners |

<details>
<summary><strong>📦 Current package versions</strong></summary>

| Package | Version declared in source |
|---|---:|
| Driver Mobile App | `1.7.5+1` |
| Police Mobile App | `1.0.0+1` |
| Admin Web Portal | `0.1.0` |
| Backend API package | `0.0.1` |
| Swagger API document | `1.0` |

</details>

---

<a id="system-roles"></a>
## 👥 System Roles

Auto Ledger contains five application roles. Each role receives only the features relevant to its operational responsibility.

| Role | Application | Main Responsibilities |
|---|---|---|
| **Driver** | Driver Mobile App | Register against a DMT-created licence, verify email, bind a device, use biometric login, view digital licence and points, generate QR sessions, review fines, pay single or multiple fines, download/print receipts, manage profile and password |
| **Traffic Officer** | Police Mobile App | Log in only during an active assigned shift, scan a Driver QR, connect to the licence, inspect licence/points/categories, select offences, issue fines, add penalty points, trigger temporary/court-case rules, view personal fine history and operational statistics |
| **Divisional Head** | Police Mobile App | Create Traffic Officers, assign and update shifts, view duty state and location, transfer officers, review dashboard statistics, resolve overdue/court cases, review revoked licences and apply decisions |
| **Police Admin** | Admin Web Portal | Create divisions, create/activate/disable Divisional Heads, review division/head information, create and maintain offence categories, configure fine amount/points/court-case classification, view Police dashboard statistics |
| **DMT Admin** | Admin Web Portal | Create driving licences, validate driver details, upload licence images, maintain vehicle categories, update licence information/status, search and review licences, inspect fines and problematic licences |

<details>
<summary><strong>🔎 Detailed role capabilities</strong></summary>

#### Driver

- Registration is allowed only when a matching DMT-created `User` and `Driving_License` record already exist.
- Email verification through a six-digit OTP.
- Device binding and new-device OTP verification.
- Password login and biometric login on the registered device.
- Digital licence presentation with image, status, points and vehicle categories.
- QR session generation and QR scan-status polling.
- Fine history, offence details, payment status and scan location.
- Single-fine and bulk-fine payment flows.
- PDF payment receipt generation and printing.
- Password change, biometric preference and logout.

#### Traffic Officer

- Login with badge number and password.
- Login and fine operations are restricted to an active assigned shift.
- QR camera permission handling and lifecycle-safe camera control.
- Driver QR scanning and ten-minute active connection session.
- Licence, points, suspension and vehicle-category review.
- Offence loading, selection, amount calculation and point calculation.
- Fine issuance with an optional note.
- Fine result, fine history and officer statistics.
- Duty location, division and Divisional Head information.
- Biometric lock, configurable auto-lock, password change and logout.

#### Divisional Head

- Login with username and password.
- Dashboard with officer, fine, court-case and revenue statistics.
- Traffic Officer registration.
- Shift assignment and shift update, including location.
- Active/off-duty officer monitoring.
- Traffic Officer transfer between active Divisional Heads.
- Court-case and overdue-fine resolution after payment.
- Revoked-licence review and resolution.
- Password recovery, biometric lock, auto-lock and logout.

#### Police Admin

- Admin login using the `POLICE` admin type.
- Division creation with validated IDs such as `DIV-001`.
- Divisional Head creation and lifecycle management.
- Automatic reassignment of unresolved records and officers when the active head changes.
- Offence-category creation, editing and activation/deactivation.
- Fine amount, penalty points and court-case classification management.
- Police overview dashboard.

#### DMT Admin

- Admin login using the `DMT` admin type.
- New driving-licence creation.
- Licence image upload through the backend or a short-lived S3 presigned URL.
- Licence and vehicle-category editing.
- Licence search by NIC.
- All-licence and licence-with-fines views.
- Suspended/revoked/problematic licence review.
- Licence-status update.
- DMT dashboard statistics.

</details>

---

<a id="core-features"></a>
## 💡 Core Features

### Identity and Access

- JWT bearer authentication.
- Password hashing using bcrypt.
- Role-based access control for administrative and enforcement operations.
- Device-bound Driver sessions using the `device-id` request header.
- Active-shift enforcement for Traffic Officer login and fine operations.
- OTP flows for registration, password reset and new-device verification.
- Biometric authentication support in both Flutter applications.
- Secure token storage on mobile devices.

### Driving Licence Management

- DMT-controlled licence creation.
- Driver identity, NIC, address, blood group, date of birth and issue date.
- Multiple vehicle classes per licence.
- Category-level issue dates, expiry dates and restrictions.
- Licence statuses: `ACTIVE`, `TEMPORARY`, `SUSPENDED`, `EXPIRED`, `REVOKED`.
- Automatic expiry evaluation based on vehicle-category expiry dates.
- Licence image storage in Amazon S3.
- Licence search, update, status management and fine-history views.

### QR Verification

- Driver-generated QR session token.
- Initial `PENDING` state.
- First successful Traffic Officer scan activates the session.
- Ten-minute active scan window.
- Scan status polling by the Driver application.
- Shift validation before scan acceptance.
- Scan-history record with Traffic Officer, Driver, licence, Divisional Head and duty location.
- Fine issuance requires the same valid active QR session.

### Fine and Penalty-Point Management

- Multiple offences can be attached to one fine.
- Fine amount and points are calculated from offence categories.
- Standard fines, court-case offences and optional comments.
- Fourteen-day fine due date.
- Point-based suspension/revocation rules.
- Temporary licence creation for eligible unpaid standard fines.
- Overdue fine processing.
- Single and bulk payment recording.
- Court-case and overdue-fine decision workflow.
- Driver, Traffic Officer, Divisional Head and DMT fine views.
- Scan location attached to returned fine history.

### Police Organisation Management

- Division creation.
- Divisional Head creation, activation and disabling.
- One active operational head per division workflow.
- Historical head records retained.
- Unresolved fine, temporary-licence and officer reassignment during head replacement.
- Traffic Officer creation and transfer.
- Shift creation and update with start/end times and duty location.
- Current officer duty-state calculation.

### Reporting and Dashboards

- Traffic Officer daily, monthly and all-time fine statistics.
- QR scan count and temporary-licence count.
- Divisional dashboard officer, fine, court and revenue metrics.
- DMT licence/fine/problematic-licence views.
- Police Admin division, head and offence metrics.

---

<a id="how-it-works"></a>
## 🔄 How It Works

Auto Ledger uses a secure QR-first process. The main workflows are described below without diagrams.

### 1. Licence provisioning and Driver registration

1. A DMT Admin creates the Driver and driving-licence record.
2. The Driver registers with NIC, email, password and device information.
3. The backend validates the pre-created licence and sends a six-digit OTP.
4. The Driver verifies the OTP.
5. The backend activates the account and returns a JWT-backed Driver session.

### 2. QR-first traffic fine process

1. The Driver generates a QR session from the Driver app.
2. A Traffic Officer logs in during an assigned active shift.
3. The officer scans the QR code using the Police app.
4. The backend validates the officer, shift, Driver and licence.
5. A ten-minute active connection is created and the scan location is recorded.
6. The officer selects offences and submits the fine.
7. The backend revalidates the session, creates the fine, adds points and applies licence-status rules.

### 3. Payment and court resolution

- A standard fine paid before its due date becomes `PAID`.
- An unpaid standard fine becomes `OVERDUE` after the deadline and can suspend the licence.
- A court-case offence creates a `COURT_CASE` fine and suspends the licence unless it is already revoked.
- Payments for overdue or court-case fines are recorded, but a Divisional Head decision is still required.
- Licence reactivation depends on remaining fines, points and other blocking conditions.

---

<a id="architecture"></a>
## 🏗️ Architecture

Auto Ledger is a full-stack monorepo with separate mobile, web, API and data layers.

| Layer | Responsibility |
|---|---|
| Driver Flutter App | Digital licence, QR sessions, fine history, payments and profile security |
| Police Flutter App | Traffic Officer and Divisional Head operations |
| Next.js Admin Portal | DMT Admin and Police Admin dashboards |
| NestJS REST API | Authentication, business rules, QR validation, fines, licences and reporting |
| PostgreSQL + Prisma | Relational source of truth and database access |
| Amazon S3 | Driving-licence image storage |
| AWS EC2 + Docker | Backend hosting |
| AWS Amplify | Admin portal hosting |
| GitLab CI/CD | Source control, review and automated deployment |

### Request flow

- Mobile and web clients communicate with the NestJS API using HTTPS REST requests.
- JWT authentication protects authorised operations.
- Driver requests also use the `device-id` header for device binding.
- Traffic Officer enforcement actions require both an active shift and an active QR session.
- The API persists application data in PostgreSQL and stores licence images in S3.

### Architectural style

- Modular NestJS backend with controller, service and module separation.
- RESTful JSON API with Swagger/OpenAPI documentation.
- Prisma ORM over PostgreSQL.
- Flutter mobile applications and a Next.js App Router portal.
- Dockerised backend deployment through GitLab and AWS.

---

<a id="technology-stack"></a>
## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| Driver Mobile | Flutter, Dart, Dio, Shared Preferences, Flutter Secure Storage, Local Auth, QR Flutter, PDF, Printing |
| Police Mobile | Flutter, Dart, HTTP, Flutter Secure Storage, Local Auth, Mobile Scanner, Permission Handler, Shared Preferences |
| Web Portal | Next.js 16, React 19, TypeScript, Axios, Tailwind CSS 4, Lucide React |
| Backend | NestJS 11, TypeScript, Passport JWT, class-validator, Swagger, Schedule, Nodemailer |
| Data | PostgreSQL, Prisma ORM |
| Object Storage | Amazon S3, AWS SDK for JavaScript v3, S3 presigned URLs |
| Infrastructure | AWS EC2, AWS Amplify Hosting, Docker, Docker Compose |
| DevOps | GitLab, GitLab CI/CD, SSH deployment |
| Security | JWT, bcrypt, OTP, device binding, role guards, active-shift guard, mobile biometrics |

---

<a id="repository-structure"></a>
## 🗂️ Repository Structure

```text
auto-ledger/
├── backend/nest-api/                    # NestJS API, Prisma schema and tests
├── frontend_apps/
│   ├── auto-ledger-frontend/            # Next.js DMT + Police Admin portal
│   ├── auto_ledger/                     # Flutter Driver application
│   └── auto_ledger_police/              # Flutter Police application
├── docker-compose.yml                   # Local infrastructure and backend
├── .gitlab-ci.yml                       # Primary deployment pipeline
├── LICENSE
└── README.md
```

<details>
<summary><strong>📁 View the complete source tree</strong></summary>

```text
auto-ledger/
├── .github/
│   └── workflows/
│       └── depoly.yml                     # Legacy/alternative GitHub deployment workflow
├── .gitlab-ci.yml                         # Primary GitLab backend deployment pipeline
├── .gitignore
├── LICENSE
├── README.md
├── docker-compose.yml                     # PostgreSQL, Redis and backend services
│
├── backend/
│   └── nest-api/
│       ├── prisma/
│       │   ├── migrations/
│       │   │   ├── 20260523165647_init_tables/
│       │   │   ├── 20260524040519_phase3_full_db/
│       │   │   ├── 20260525062155_init_postgres_schema/
│       │   │   ├── 20260619135146_add_is_active_to_head/
│       │   │   ├── 20260711060309_init/
│       │   │   ├── 20260713070551_new_db_changes/
│       │   │   ├── 20260713081919_implement_method2_historical_heads/
│       │   │   ├── 20260718134223_add_qr_session/
│       │   │   └── 20260719142736_user_otps/
│       │   ├── migration_lock.toml
│       │   ├── schema.prisma               # Database schema and relationships
│       │   └── seed.ts                     # Initial DMT and Police Admin seeding
│       ├── src/
│       │   ├── auth/
│       │   │   ├── auth.controller.ts
│       │   │   ├── auth.module.ts
│       │   │   ├── auth.service.ts
│       │   │   ├── jwt-auth.guard.ts
│       │   │   ├── jwt.strategy.ts
│       │   │   ├── roles.decorator.ts
│       │   │   └── roles.guard.ts
│       │   ├── common/
│       │   │   ├── decorators/
│       │   │   │   └── skip-device-check.decorator.ts
│       │   │   └── guard/
│       │   │       ├── active-shift.guard.ts
│       │   │       └── device.guard.ts
│       │   ├── fines/
│       │   │   ├── fines.controller.ts
│       │   │   ├── fines.module.ts
│       │   │   └── fines.service.ts
│       │   ├── license/
│       │   │   ├── license.controller.ts
│       │   │   ├── license.module.ts
│       │   │   └── license.service.ts
│       │   ├── officers/
│       │   │   ├── officers.controller.ts
│       │   │   ├── officers.module.ts
│       │   │   └── officers.service.ts
│       │   ├── prisma/
│       │   │   ├── prisma.module.ts
│       │   │   └── prisma.service.ts
│       │   ├── qr/
│       │   │   ├── qr.controller.ts
│       │   │   ├── qr.module.ts
│       │   │   └── qr.service.ts
│       │   ├── users/
│       │   │   ├── users.controller.ts
│       │   │   ├── users.module.ts
│       │   │   └── users.service.ts
│       │   ├── app.controller.ts
│       │   ├── app.module.ts
│       │   ├── app.service.ts
│       │   └── main.ts
│       ├── test/
│       │   └── app.e2e-spec.ts
│       ├── .dockerignore
│       ├── .gitignore
│       ├── .prettierrc
│       ├── Dockerfile
│       ├── eslint.config.mjs
│       ├── nest-cli.json
│       ├── package-lock.json
│       ├── package.json
│       ├── tsconfig.build.json
│       └── tsconfig.json
│
└── frontend_apps/
    ├── auto-ledger-frontend/               # DMT Admin + Police Admin web portal
    │   ├── app/
    │   │   ├── dmt-dashboard/
    │   │   │   ├── add-driver/page.tsx
    │   │   │   ├── drivers/page.tsx
    │   │   │   ├── revoked/page.tsx
    │   │   │   ├── layout.tsx
    │   │   │   └── page.tsx
    │   │   ├── police-dashboard/
    │   │   │   ├── divisional-heads/page.tsx
    │   │   │   ├── divisions/page.tsx
    │   │   │   ├── offense/page.tsx
    │   │   │   ├── layout.tsx
    │   │   │   └── page.tsx
    │   │   ├── login/page.tsx
    │   │   ├── favicon.ico
    │   │   ├── globals.css
    │   │   ├── layout.tsx
    │   │   └── page.tsx
    │   ├── lib/
    │   │   └── api.ts                      # Axios client and JWT interceptor
    │   ├── public/
    │   │   ├── Sri_Lanka_Police_logo.png
    │   │   ├── dmt_logo.png
    │   │   ├── google14e1e411f9449f73.html
    │   │   ├── sitemap.xml
    │   │   └── static SVG assets
    │   ├── next.config.ts
    │   ├── package-lock.json
    │   ├── package.json
    │   ├── postcss.config.mjs
    │   ├── tsconfig.json
    │   └── eslint.config.mjs
    │
    ├── auto_ledger/                        # Driver Flutter application
    │   ├── android/                        # Flutter Android platform project
    │   ├── ios/                            # Flutter iOS platform project
    │   ├── assets/
    │   │   ├── icon/app_icon.png
    │   │   ├── emblem.png
    │   │   ├── flag.png
    │   │   └── punkalasa.png
    │   ├── lib/
    │   │   ├── screens/
    │   │   │   ├── fines_screen.dart
    │   │   │   ├── home_screen.dart
    │   │   │   ├── login_screen.dart
    │   │   │   ├── profile_screen.dart
    │   │   │   ├── register_screen.dart
    │   │   │   └── splash_screen.dart
    │   │   ├── services/
    │   │   │   ├── api_service.dart
    │   │   │   ├── auth_service.dart
    │   │   │   ├── biometric_service.dart
    │   │   │   ├── pdf_service.dart
    │   │   │   └── user_service.dart
    │   │   ├── utils/
    │   │   │   ├── device_info.dart
    │   │   │   ├── secure_storage.dart
    │   │   │   └── settings_util.dart
    │   │   ├── widgets/
    │   │   │   ├── glass_card.dart
    │   │   │   ├── glass_container.dart
    │   │   │   └── qr_dialog.dart
    │   │   └── main.dart
    │   ├── analysis_options.yaml
    │   ├── pubspec.lock
    │   └── pubspec.yaml
    │
    └── auto_ledger_police/                 # Traffic Officer + Divisional Head Flutter app
        ├── android/                        # Flutter Android platform project
        ├── ios/                            # Flutter iOS platform project
        ├── linux/                          # Flutter Linux platform project
        ├── macos/                          # Flutter macOS platform project
        ├── assets/
        │   ├── icon/app_icon.png
        │   └── images/sl_police_logo.png
        ├── lib/
        │   ├── core/
        │   │   ├── constants/
        │   │   │   ├── api_constants.dart
        │   │   │   └── app_routes.dart
        │   │   ├── navigation/app_route_observer.dart
        │   │   ├── network/api_client.dart
        │   │   ├── services/device_service.dart
        │   │   ├── storage/token_storage.dart
        │   │   ├── theme/app_theme.dart
        │   │   └── utils/app_error_handler.dart
        │   ├── features/
        │   │   ├── auth/
        │   │   │   ├── screens/
        │   │   │   │   ├── biometric_auth_screen.dart
        │   │   │   │   ├── forgot_password_screen.dart
        │   │   │   │   └── login_screen.dart
        │   │   │   └── services/auth_service.dart
        │   │   ├── divisional_officer/
        │   │   │   ├── screens/
        │   │   │   │   ├── add_traffic_officer_screen.dart
        │   │   │   │   ├── assign_shift_screen.dart
        │   │   │   │   ├── court_cases_screen.dart
        │   │   │   │   ├── do_dashboard_screen.dart
        │   │   │   │   ├── revoked_licenses_screen.dart
        │   │   │   │   ├── settings_screen.dart
        │   │   │   │   └── traffic_officer_list_screen.dart
        │   │   │   └── services/
        │   │   │       ├── fine_service.dart
        │   │   │       └── officer_service.dart
        │   │   ├── onboarding/screens/onboarding_screen.dart
        │   │   └── traffic_officer/
        │   │       ├── screens/
        │   │       │   ├── fine_confirmation_screen.dart
        │   │       │   ├── fine_history_screen.dart
        │   │       │   ├── fine_result_screen.dart
        │   │       │   ├── license_preview_screen.dart
        │   │       │   ├── offense_select_screen.dart
        │   │       │   ├── profile_screen.dart
        │   │       │   ├── qr_scanner_screen.dart
        │   │       │   ├── settings_screen.dart
        │   │       │   └── to_dashboard_screen.dart
        │   │       ├── services/traffic_fine_service.dart
        │   │       └── widgets/
        │   │           ├── about_dialog.dart
        │   │           ├── change_password_dialog.dart
        │   │           ├── dashboard_stats_card.dart
        │   │           ├── glass_card.dart
        │   │           ├── glass_dialog.dart
        │   │           ├── liquid_nav_bar.dart
        │   │           └── recent_fine_card.dart
        │   ├── models/
        │   │   ├── auth_response_model.dart
        │   │   ├── fine_model.dart
        │   │   ├── license_model.dart
        │   │   ├── offense_model.dart
        │   │   ├── officer_model.dart
        │   │   └── shift_model.dart
        │   ├── shared/widgets/
        │   │   ├── app_button.dart
        │   │   ├── app_text_field.dart
        │   │   ├── error_view.dart
        │   │   └── loading_view.dart
        │   └── main.dart
        ├── pubspec.lock
        └── pubspec.yaml
```

</details>

---

<a id="local-development"></a>
## ⚡ Local Development

### Prerequisites

- Git
- Node.js 20+
- npm
- Docker Engine and Docker Compose
- Flutter SDK compatible with Dart `>=3.5.0 <4.0.0`
- Android Studio/Xcode as required for the target mobile platform
- PostgreSQL 15 when not using Docker

### 1. Clone the GitLab Repository

```bash
git clone https://gitlab.com/<group>/auto-ledger.git
cd auto-ledger
```

### 2. Start Local Infrastructure

```bash
docker compose up -d db redis
```

The current backend stores OTP values in PostgreSQL. The Redis container is provisioned for caching/real-time infrastructure but is not directly used by the supplied backend services.

### 3. Run the Backend

```bash
cd backend/nest-api
npm ci
npx prisma generate
npx prisma migrate dev
npx prisma db seed
npm run start:dev
```

Backend endpoints:

- API: `http://localhost:3000`
- Swagger: `http://localhost:3000/api/docs`

### 4. Run the Admin Web Portal

```bash
cd frontend_apps/auto-ledger-frontend
npm ci
npm run dev
```

Open `http://localhost:3000` only when the backend is on a different port, or start the web app on another port:

```bash
npm run dev -- --port 3001
```

### 5. Run the Driver App

```bash
cd frontend_apps/auto_ledger
flutter pub get
flutter run
```

### 6. Run the Police App

```bash
cd frontend_apps/auto_ledger_police
flutter pub get
flutter run
```

---

<a id="deployment"></a>
## ☁️ Deployment

| Component | Target |
|---|---|
| Backend API | Docker on AWS EC2 |
| Admin Portal | AWS Amplify Hosting |
| Licence Images | Amazon S3 |
| Deployment Pipeline | GitLab CI/CD over SSH |

<details>
<summary><strong>🖥️ Backend, S3 and Amplify deployment</strong></summary>

### Backend on AWS EC2

The NestJS backend is containerised and deployed to an AWS EC2 instance. The current GitLab pipeline connects to the instance through SSH, synchronises the `main` branch, rebuilds the backend image and restarts the backend service with Docker Compose.

**Current deployment command executed by CI/CD:**

```bash
cd ~/auto-ledger
git fetch origin
git reset --hard origin/main
docker compose build --no-cache backend
docker compose up -d backend
```

### Amazon S3 Licence Images

Licence images are stored under the `licenses/` object prefix. The backend supports:

1. A short-lived presigned PUT upload URL.
2. Direct multipart upload through the backend.

The presigned upload URL currently expires after **60 seconds**.

#### IAM Role Model

The production EC2 instance should use an attached IAM role/instance profile with least-privilege access to the required S3 bucket. Static AWS access keys must not be committed to GitLab or stored in the repository.

Minimum conceptual permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::<AUTO_LEDGER_BUCKET>/licenses/*"
    }
  ]
}
```

### Web Portal on AWS Amplify

The Next.js administrative portal is hosted through AWS Amplify Hosting and connected to the GitLab repository for continuous deployment.

- Application directory: `frontend_apps/auto-ledger-frontend`
- Production domain: `https://auto-ledger.tech`
- Current public endpoint: `https://www.auto-ledger.tech`
- Required build-time API variable: `NEXT_PUBLIC_API_URL`
- Required image-host variable: `NEXT_PUBLIC_S3_HOSTNAME`

### Domain

The `.tech` domain is connected to AWS Amplify using Amplify custom-domain configuration and DNS records. HTTPS should remain mandatory for the web portal and all API traffic.

</details>

<details>
<summary><strong>🐳 Docker commands</strong></summary>

### Full Local Stack

```bash
docker compose up -d --build
```

### Backend Only

```bash
docker compose build backend
docker compose up -d backend
```

### Common Operations

```bash
# Show service state
docker compose ps

# Follow backend logs
docker compose logs -f backend

# Restart backend
docker compose restart backend

# Stop services
docker compose down

# Stop and remove local database volume — destructive
docker compose down -v
```

</details>

<details>
<summary><strong>🦊 GitLab CI/CD</strong></summary>

### Current Pipeline

The `main` branch deployment follows this flow:

1. GitLab starts the deploy job after a push or merge to `main`.
2. The runner loads the protected SSH deployment key.
3. The job connects to the EC2 instance.
4. The server checkout is reset to `origin/main`.
5. Docker rebuilds the backend image without cache.
6. Docker Compose restarts the backend service.

### Deployment Variables

```text
SSH_PRIVATE_KEY
EC2_IP
EC2_USER
```

### Recommended 2026 Pipeline Stages

The following stages are recommended but are not all implemented in the current pipeline:

```text
validate → test → security → build → package → deploy-staging → verify → deploy-production → release
```

Recommended jobs:

- Backend formatting and ESLint check.
- Backend unit and end-to-end tests.
- Prisma schema validation.
- Next.js lint and production build.
- Flutter analyse and tests for both apps.
- Secret detection and dependency scanning.
- SAST and container scanning.
- Docker image build with immutable tag.
- Staging deployment and smoke test.
- Protected manual production approval.
- GitLab Release and mobile artifact publication.

### SSH Security

- Use a dedicated deployment key, not a personal SSH key.
- Protect and mask CI/CD variables.
- Restrict the EC2 account and key to only the commands required for deployment.
- Pin the EC2 host key instead of trusting an unverified changing host.
- Prefer GitLab OpenID Connect and AWS role assumption for AWS API operations.

</details>

<details>
<summary><strong>⚡ AWS Amplify configuration</strong></summary>

### Monorepo Build Configuration Example

Create `amplify.yml` at the repository root when build settings are managed as code:

```yaml
version: 1
applications:
  - appRoot: frontend_apps/auto-ledger-frontend
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
          - .next/cache/**/*
```

### Amplify Environment Variables

```text
NEXT_PUBLIC_API_URL=https://<production-api-host>
NEXT_PUBLIC_S3_HOSTNAME=<bucket-name>.s3.<region>.amazonaws.com
```

### Custom Domain Steps

1. Connect the GitLab repository and production branch to Amplify Hosting.
2. Set the monorepo application root to `frontend_apps/auto-ledger-frontend`.
3. Configure build environment variables.
4. Add `auto-ledger.tech` under **Hosting → Custom domains**.
5. Create/verify the required DNS records.
6. Verify the managed TLS certificate.
7. Redirect the apex domain and `www` consistently.
8. Run a production smoke test for login, dashboard routing and API access.

</details>

---

<a id="business-rules"></a>
## 🧭 Business Rules

| Rule | Current Implementation |
|---|---|
| Driver registration prerequisite | DMT-created Driver user and licence must already exist |
| Registration/reset/device OTP validity | 5 minutes |
| Traffic Officer login | Denied outside an active shift |
| Fine issuance | Requires authenticated Traffic Officer, active shift and active QR session |
| QR active window | 10 minutes from first successful scan |
| QR scan audit | Stores officer, Driver, licence, head, scan time and shift location |
| Standard fine due date | 14 days after issuance |
| 24-point threshold | One-month suspension on first threshold trigger |
| 50-point threshold | Six-month suspension on first threshold trigger |
| 100-point threshold | Licence revocation and triggering-fine reference |
| Court-case offence | Fine status `COURT_CASE`; licence suspended unless already revoked |
| Eligible standard unpaid fine | Temporary licence may be created until fine due date |
| Overdue pending fine | Fine becomes `OVERDUE`, licence is suspended and temporary licence is removed |
| Standard on-time payment | Fine becomes `PAID`; licence may reactivate when no other blocking condition exists |
| Overdue/court payment | Payment is recorded; Divisional Head decision remains required |
| Scheduled processing | Runs every 5 minutes |
| Licence expiry | Evaluated from the latest vehicle-category expiry date |
| Officer transfer | Blocked while officer has an active shift; future active shifts are cancelled after transfer |
| Head replacement | Unresolved fines, valid temporary licences and officers are reassigned |

---

<a id="security"></a>
## 🔐 Security

### Implemented Controls

- JWT bearer authentication with expiry validation.
- bcrypt password hashing.
- Role-based method guards.
- Driver device-binding guard using `device-id`.
- Active-shift guard for enforcement operations.
- DTO validation with unknown-field whitelisting and transformation.
- Email OTPs with expiry.
- Mobile secure storage.
- Mobile biometric authentication and auto-lock.
- S3 presigned upload support.
- Transactional database updates for fine, payment, head replacement and licence updates.

### Production Hardening Checklist

- Restrict CORS to approved Amplify/mobile origins instead of `app.enableCors()` without an origin allowlist.
- Add explicit JWT and role guards to all DMT, QR and offence read routes that currently expose data publicly.
- Verify QR-session ownership so one Driver’s token cannot be generated or polled without authorisation.
- Add rate limiting to login, OTP, QR and payment endpoints.
- Store secrets only in EC2/Amplify/GitLab secret managers or protected CI/CD variables.
- Use an EC2 IAM role instead of long-lived S3 access keys.
- Keep the S3 bucket private and return controlled signed read URLs unless public image delivery is intentionally required.
- Validate uploaded file type, size, extension and image content.
- Validate payment amounts against backend-calculated offence totals; never trust client-submitted amounts.
- Integrate a verified payment gateway before describing payments as financially settled.
- Add audit logging for admin changes, verdicts, transfers and status changes.
- Add request correlation IDs, structured logs, health checks and alerts.
- Place the EC2 API behind HTTPS through an Application Load Balancer, reverse proxy or managed edge service.
- Use database backups, point-in-time recovery and a tested restoration procedure.
- Rotate seeded/default credentials immediately and never publish them in documentation.
- Add dependency, secret, SAST and container-image scanning to GitLab CI/CD.

---

<a id="technical-reference"></a>
## 📚 Technical Reference

The detailed implementation reference is kept below in expandable sections so the main README remains easy to scan.

<details>
<summary><strong>🧩 Backend modules and methods</strong></summary>

### Application Bootstrap

| File / Method | Responsibility |
|---|---|
| `main.ts → bootstrap()` | Creates the Nest application, enables CORS, registers global validation, configures Swagger at `/api/docs`, and starts the server |
| `AppModule` | Loads configuration, scheduling, Prisma, authentication, users, licences, fines, QR and officer modules |
| `AppService.getHello()` | Basic application/health response |
| `PrismaService.onModuleInit()` | Connects Prisma when the module starts |

### Authentication Service

| Method | Responsibility |
|---|---|
| `sendOtpEmail()` | Sends registration, reset or device-verification OTP email |
| `generateOtp()` | Generates a six-digit OTP |
| `loginAdmin()` | Authenticates DMT or Police Admin and issues a role-bearing JWT |
| `loginHead()` | Authenticates an active Divisional Head and includes division context |
| `loginOfficer()` | Authenticates a Traffic Officer, requires an active shift, and returns division/head/duty-location data |
| `changePassword()` | Changes a Divisional Head or Traffic Officer password |
| `requestHeadPasswordReset()` | Creates and emails a Divisional Head reset OTP |
| `verifyHeadResetOtp()` | Validates a Divisional Head reset OTP |
| `resetHeadPassword()` | Replaces a Divisional Head password and clears OTP data |
| `resendHeadOtp()` | Reissues the Divisional Head reset OTP |
| `requestOfficerPasswordReset()` | Creates and emails a Traffic Officer reset OTP |
| `verifyOfficerResetOtp()` | Validates a Traffic Officer reset OTP |
| `resetOfficerPassword()` | Replaces a Traffic Officer password and clears OTP data |
| `resendOfficerOtp()` | Reissues the Traffic Officer reset OTP |
| `generateUserToken()` | Creates the Driver JWT and user response |
| `registerUser()` | Registers a Driver against an existing DMT-created licence and sends OTP |
| `verifyRegistration()` | Verifies Driver registration OTP and activates email verification |
| `loginUser()` | Authenticates Driver password and validates registered device |
| `verifyNewDevice()` | Rebinds a Driver account to a verified new device |
| `biometricLogin()` | Issues a Driver session after local biometric approval and device validation |
| `changeUserPassword()` | Changes a Driver password |
| `requestPasswordReset()` | Starts Driver password recovery |
| `verifyUserResetOtp()` | Validates Driver password-reset OTP |
| `resetPassword()` | Replaces Driver password and clears OTP data |
| `resendRegistrationOtp()` | Reissues Driver registration OTP |
| `resendResetOtp()` | Reissues Driver password-reset OTP |
| `resendDeviceOtp()` | Reissues Driver device-verification OTP |

### Licence Service

| Method | Responsibility |
|---|---|
| `autoActivateLicenses()` | Reactivates eligible suspended licences when suspension and unresolved-fine conditions allow |
| `getS3UploadUrl()` | Creates a 60-second presigned S3 upload URL and resulting object URL |
| `uploadImageToS3()` | Uploads an image through the backend to the S3 `licenses/` prefix |
| `createLicense()` | Creates a pending User when required, then creates a licence and categories |
| `getMyLicense()` | Returns the logged-in Driver licence, unresolved fines, temporary licences and categories |
| `updateStatus()` | Updates the licence status |
| `getLicenseByNIC()` | Returns a full licence, categories, fines, offences and payments by NIC |
| `getAllLicenses()` | Lists licences with optional NIC filtering |
| `updateLicenseDetails()` | Updates licence data and replaces categories transactionally when supplied |
| `getLicensesWithFines()` | Returns licences that contain fine records |
| `getRevokedLicenses()` | Returns revoked licences linked to the current Divisional Head |
| `resolveRevokedLicense()` | Applies the Divisional Head decision and resets point-history flags when activation is allowed |

### QR Service

| Method | Responsibility |
|---|---|
| `generateQrSession()` | Creates a `PENDING` QR session and returns its token |
| `getQrStatus()` | Returns session state, expiry and scan state; marks elapsed active sessions as expired |
| `scanQr()` | Validates licence, officer and active shift; activates/reuses the ten-minute session; records scan location; returns Driver and licence data |

### Fine Service

| Method | Responsibility |
|---|---|
| `handleCron()` | Runs overdue-fine and licence-expiry processing every five minutes |
| `expireLicensesIfExpired()` | Marks licences expired when all applicable category validity has ended |
| `sendWarningEmail()` | Emails point-based suspension/revocation warnings |
| `autoActivateLicenses()` | Restores eligible suspended licences |
| `processOverdueFines()` | Changes elapsed pending fines to overdue, suspends licences and removes temporary licences |
| `issueFine()` | Requires an active QR session, creates the fine and offence links, adds points, changes licence state and creates a temporary licence when eligible |
| `getMyFines()` | Returns Driver fine history with offences, officer, payment and scan location |
| `payFine()` | Records one payment and updates fine/licence state |
| `payBulkFines()` | Records multiple payments in one transaction and updates licence state |
| `resolveOverdueCourtCase()` | Allows the responsible Divisional Head to resolve a paid overdue/court-case fine |
| `resolveRevokedLicense()` | Legacy/internal revoked-licence resolution method in the Fine service |
| `getAllOffenses()` | Lists offence categories by code |
| `createOffenseCategory()` | Creates an offence category for the Police Admin |
| `updateOffenseCategory()` | Updates offence name, points, amount and court-case flag |
| `toggleOffenseStatus()` | Enables or disables an offence category |
| `getAllFinesForDMT()` | Lists all fines and associated scan location for DMT views |
| `getProblematicLicensesForDMT()` | Lists suspended and revoked licences |
| `getCourtCasesByDH()` | Lists the current Divisional Head’s overdue and court-case fines |
| `getDashboardStats()` | Produces Divisional Head officer, fine, court-case and revenue statistics |
| `getTrafficOfficerStats()` | Produces officer daily/monthly/all-time statistics, QR scans and temporary-licence count |
| `getOfficerFines()` | Returns an officer’s fine history and scan location |

### Officer Service

| Method | Responsibility |
|---|---|
| `createDivision()` | Creates a unique Police division |
| `activateDivisionalHead()` | Activates a head and reassigns unresolved records/officers from the previous active head |
| `disableDivisionalHead()` | Disables a head only when another active head is available and transfers operational records |
| `getDivisionWithAllHeads()` | Returns one division with active and historical heads |
| `createDivisionalHead()` | Creates a head, hashes the password and activates the account workflow |
| `createTrafficOfficer()` | Creates an officer under the authenticated Divisional Head |
| `assignShift()` | Creates an active shift with date, time range and location |
| `updateShift()` | Updates selected shift fields |
| `getOfficerShifts()` | Lists an officer’s shifts newest first |
| `getDivisionOfficers()` | Lists the current head’s officers with computed duty status/current shift |
| `getAllDivisions()` | Lists divisions with active heads |
| `getAllDivisionalHeads()` | Lists heads with division data and active state |
| `transferOfficer()` | Transfers an officer after ensuring no active shift and cancels future shifts |

### User Service

| Method | Responsibility |
|---|---|
| `getUserById()` | Returns Driver profile data |
| `updateUserDevice()` | Changes the Driver device identifier |
| `verifyEmail()` | Marks the Driver email verified |

</details>

<details>
<summary><strong>🔌 REST API reference</strong></summary>

Base URL examples:

```text
Local:      http://localhost:3000
Production: https://api.auto-ledger.tech        # Example only; replace with the real API hostname
Swagger:    https://api.auto-ledger.tech/api/docs
```

### Health

| Method | Route | Access | Description |
|---|---|---|---|
| `GET` | `/` | Public | Basic backend response |

### Authentication

| Method | Route | Access | Description |
|---|---|---|---|
| `POST` | `/auth/admin/login` | Public | DMT/Police Admin login |
| `POST` | `/auth/head/login` | Public | Divisional Head login |
| `POST` | `/auth/officer/login` | Public | Traffic Officer login with active-shift requirement |
| `POST` | `/auth/user/register` | Public | Driver registration step 1 |
| `POST` | `/auth/user/verify-registration` | Public | Driver registration OTP verification |
| `POST` | `/auth/user/resend-registration-otp` | Public | Resend registration OTP |
| `POST` | `/auth/user/login` | Public | Driver password/device login |
| `POST` | `/auth/user/biometric-login` | Public | Driver biometric/device login |
| `POST` | `/auth/user/verify-device` | Public | New-device OTP verification |
| `POST` | `/auth/user/resend-device-otp` | Public | Resend device OTP |
| `POST` | `/auth/user/forgot-password-check` | Public | Start Driver password recovery |
| `POST` | `/auth/user/verify-reset-otp` | Public | Verify Driver reset OTP |
| `POST` | `/auth/user/reset-password` | Public | Reset Driver password |
| `POST` | `/auth/user/resend-reset-otp` | Public | Resend Driver reset OTP |
| `POST` | `/auth/head/forgot-password-request` | Public | Start Divisional Head recovery |
| `POST` | `/auth/head/verify-reset-otp` | Public | Verify Divisional Head OTP |
| `POST` | `/auth/head/reset-password` | Public | Reset Divisional Head password |
| `POST` | `/auth/head/resend-otp` | Public | Resend Divisional Head OTP |
| `POST` | `/auth/officer/forgot-password-request` | Public | Start Traffic Officer recovery |
| `POST` | `/auth/officer/verify-reset-otp` | Public | Verify Traffic Officer OTP |
| `POST` | `/auth/officer/reset-password` | Public | Reset Traffic Officer password |
| `POST` | `/auth/officer/resend-otp` | Public | Resend Traffic Officer OTP |
| `PATCH` | `/auth/change-password` | JWT | Change Divisional Head/Traffic Officer password |
| `PATCH` | `/auth/user/change-password` | JWT | Change Driver password |

### Users

| Method | Route | Access | Description |
|---|---|---|---|
| `GET` | `/users/profile` | JWT | Logged-in Driver profile |
| `PATCH` | `/users/device` | JWT | Update Driver device ID |
| `PATCH` | `/users/verify-email` | JWT | Mark Driver email verified |

### Driving Licences

All licence-controller routes currently use JWT, role and device guards at controller level. Routes without an explicit `@Roles(...)` decorator are authenticated but not restricted to one role by the current controller implementation.

| Method | Route | Access | Description |
|---|---|---|---|
| `POST` | `/license` | JWT; intended DMT Admin | Create licence and vehicle categories |
| `GET` | `/license/get-upload-url?fileName=&fileType=` | JWT; intended DMT Admin | Create S3 presigned upload URL |
| `POST` | `/license/upload-image` | DMT Admin | Upload image through backend multipart form |
| `GET` | `/license/my-license` | JWT + Driver device validation | Current Driver licence |
| `PATCH` | `/license/:id/status` | DMT Admin | Update licence status |
| `GET` | `/license/search/:nic` | DMT Admin or Police Admin | Search licence by NIC |
| `GET` | `/license/all?nic=` | DMT Admin | List/search licences |
| `PATCH` | `/license/:id/update` | DMT Admin | Update licence and categories |
| `GET` | `/license/with-fines?nic=` | DMT Admin | Licences containing fine history |
| `GET` | `/license/revoked` | Divisional Head | Revoked licences belonging to the head |
| `PATCH` | `/license/:id/resolve-revoked` | Divisional Head | Resolve revoked licence decision |

### QR Sessions

| Method | Route | Access | Description |
|---|---|---|---|
| `POST` | `/qr/generate` | Public in current controller; intended Driver | Generate QR session token |
| `GET` | `/qr/status/:sessionId` | Public in current controller; intended Driver | Poll QR session state |
| `POST` | `/qr/scan/:sessionId` | Traffic Officer | Scan/activate QR and return licence details |

### Fines, Payments and Court Cases

| Method | Route | Access | Description |
|---|---|---|---|
| `POST` | `/fines` | Traffic Officer + active shift | Issue fine using an active QR session |
| `GET` | `/fines/officer-stats` | Traffic Officer + active shift | Officer statistics |
| `GET` | `/fines/officer-fines` | Traffic Officer + active shift | Officer fine history |
| `GET` | `/fines/my-fines` | Driver JWT + device validation | Driver fine history |
| `POST` | `/fines/:id/pay` | Driver JWT + device validation | Pay one fine |
| `POST` | `/fines/pay-bulk` | Driver JWT + device validation | Pay multiple fines |
| `PATCH` | `/fines/:id/resolve-overdue` | Divisional Head | Resolve a paid overdue/court case |
| `GET` | `/fines/offenses` | Public in current controller | List offence categories |
| `POST` | `/fines/offenses` | Police Admin | Create offence category |
| `PATCH` | `/fines/offenses/:id` | Police Admin | Update offence category |
| `PATCH` | `/fines/offenses/:id/toggle` | Police Admin | Toggle offence active state |
| `GET` | `/fines/court-cases` | Divisional Head | Current head’s overdue/court cases |
| `GET` | `/fines/dashboard-stats` | Divisional Head | Divisional dashboard statistics |
| `GET` | `/fines/dmt/all-fines` | Public in current controller; intended DMT Admin | All fine records for DMT |
| `GET` | `/fines/dmt/problematic-licenses` | Public in current controller; intended DMT Admin | Suspended/revoked licences |

### Police Organisation and Shifts

| Method | Route | Access | Description |
|---|---|---|---|
| `POST` | `/officers/division` | Police Admin | Create division |
| `POST` | `/officers/head` | Police Admin | Create Divisional Head |
| `PATCH` | `/officers/head/:id/activate` | Police Admin | Activate head and transfer operational records |
| `PATCH` | `/officers/head/:id/disable` | Police Admin | Disable head and transfer operational records |
| `GET` | `/officers/division/:id/heads` | Police Admin | Division with all head records |
| `POST` | `/officers/officer` | Divisional Head | Create Traffic Officer |
| `POST` | `/officers/shift` | Divisional Head | Assign shift |
| `PATCH` | `/officers/shift/:id` | Divisional Head | Update shift |
| `GET` | `/officers/my-division?search=` | Divisional Head | Officers in current division |
| `GET` | `/officers/:id/shifts` | Divisional Head | Officer shift history |
| `GET` | `/officers/divisions` | Police Admin | All divisions |
| `GET` | `/officers/divisional-heads` | Police Admin or Divisional Head | All heads |
| `PATCH` | `/officers/transfer/:id` | Divisional Head | Transfer officer to another active head |

</details>

<details>
<summary><strong>📱 Frontend application reference</strong></summary>

### Admin Web Portal Routes

| Route | Role | Main Features and Functions |
|---|---|---|
| `/login` | DMT Admin / Police Admin | Admin type selection, credentials validation, JWT storage, role-based redirect |
| `/dmt-dashboard` | DMT Admin | Dashboard statistics and navigation |
| `/dmt-dashboard/add-driver` | DMT Admin | Create/edit licence, validate fields, manage vehicle categories, upload image |
| `/dmt-dashboard/drivers` | DMT Admin | List licences, search/filter, open edit modal, update licence/category/image data |
| `/dmt-dashboard/revoked` | DMT Admin | Load suspended/revoked/problematic licences |
| `/police-dashboard` | Police Admin | Division, head and offence overview statistics |
| `/police-dashboard/divisions` | Police Admin | Create/list divisions and validate division IDs |
| `/police-dashboard/divisional-heads` | Police Admin | Create heads and activate/disable accounts |
| `/police-dashboard/offense` | Police Admin | Create, edit, paginate and enable/disable offence categories |

#### Web Function Index

- `lib/api.ts`: Axios base URL configuration and JWT request interceptor.
- Login: `determineGreeting()`, `handleLogin()`.
- DMT add/edit: `getInitialEditingId()`, `getInitialFormData()`, `handleCategoryChange()`, `handleClear()`, `handleImageUpload()`, `handleSubmit()`.
- DMT drivers: `fetchDrivers()`, `loadData()`, `openModal()`, `closeModal()`, `handleEditChange()`, `handleCategoryEdit()`, `handleImageUpload()`, `saveUpdates()`, `validateAge()`, `validateIssueDate()`.
- DMT dashboard: `loadDashboardData()`.
- DMT problematic licences: `loadLicenses()`.
- Police divisions: `fetchDivisions()`, `loadDivisions()`, `handleDivisionSubmit()`, `handleIdChange()`, `showToast()`.
- Police heads: `fetchData()`, `loadData()`, `handleHeadSubmit()`, `handleToggleStatus()`, `showToast()`.
- Police offences: `fetchOffenses()`, `loadFines()`, `handleFineSubmit()`, `handleEditClick()`, `handleModalSave()`, `handleToggleActive()`, `paginate()`, `showToast()`.
- Police dashboard: `fetchDashboardData()`.
- Layouts: `getHeaderDetails()`, `handleLogout()`, `handleResize()` and responsive sidebar handling.

### Driver Mobile App Screens

| Screen | Main Features |
|---|---|
| Splash | Restores token state and navigates to login/home |
| Register | Driver input validation, registration request and OTP dialog |
| Login | Password login, biometric login, new-device verification, forgot-password flow |
| Home | Digital licence, points, categories, status, temporary licence, QR generation, recent activity |
| Fines | Pending/paid tabs, selection, single/bulk payment, card input, points history and receipt |
| Profile | Driver/licence profile, points display, password change, biometric preference and logout |
| QR Dialog | QR display, countdown, scan-status polling and scan-complete callback |

#### Driver Service and Functional Method Index

- `ApiService.init()` — loads `.env`, configures Dio, auth token and device headers.
- `AuthService`: `registerUser()`, `verifyRegistration()`, `resendRegistrationOtp()`, `loginUser()`, `forgotPasswordCheck()`, `verifyResetOtp()`, `resendResetOtp()`, `resetPassword()`, `biometricLogin()`, `verifyDevice()`, `resendDeviceOtp()`, `headForgotPasswordRequest()`, `headVerifyResetOtp()`, `headResetPassword()`, `resendHeadOtp()`, `officerForgotPasswordRequest()`, `officerVerifyResetOtp()`, `officerResetPassword()`, `resendOfficerOtp()`, `logout()`.
- `BiometricService`: `checkBiometricsAvailable()`, `authenticate()`.
- `PdfService.generateAndPrintReceipt()` — builds and prints payment receipt PDF.
- `UserService.changePassword()`.
- `DeviceInfoUtil.getDeviceId()` and internal unique-ID generation.
- `SecureStorage`: `saveToken()`, `getToken()`, `deleteToken()`, `saveNic()`, `getNic()`, `deleteNic()`.
- `SettingsUtil`: `isBiometricEnabled()`, `setBiometricEnabled()`.
- Home flow: `_fetchLicenseData()`, `_generateQR()`, `_showQrDialog()`, `_showTemporaryLicenseSheet()`, `_showPointsWarning()`, `_showInAppPushNotification()`, `_logout()`.
- Fine flow: `_fetchFines()`, `_toggleSelection()`, `_calculateTotalSelectedAmount()`, `_showPaymentDialog()`, `_processPayment()`, `_showReceiptDialog()`, `_handleTabChange()`.
- Login flow: `_handleLogin()`, `_handleBiometricLogin()`, `_showDeviceVerificationDialog()`, `_showForgotPasswordInitialDialog()`, `_showForgotPasswordOTPDialog()`, `_showResetPasswordDialog()`.
- Registration flow: `_validateInputs()`, `_handleRegister()`, `_showOTPDialog()`.
- Profile flow: `_fetchUserProfile()`, `_checkBiometricAvailability()`, `_checkBiometricStatus()`, `_showBiometricPasswordDialog()`, `_showChangePasswordDialog()`, `_changePassword()`, `_logout()`.
- QR flow: `_startCountdown()`, `_startPolling()`, `_onQrScanned()`.

### Police Mobile App Screens

#### Shared Authentication and Session

- Onboarding and role-aware login.
- Smart login selection for badge number or Divisional Head username.
- Active-shift-aware Traffic Officer login.
- Password recovery for both Police roles.
- JWT expiry extraction and secure session restoration.
- Biometric application lock.
- Configurable auto-lock and lifecycle handling.
- Role-based dashboard routing.

#### Traffic Officer Screens

| Screen | Main Features |
|---|---|
| Dashboard | Officer identity, duty shift/location, statistics, recent fines and navigation |
| QR Scanner | Permission request, camera lifecycle, flash, QR validation and session verification |
| Licence Preview | Driver/licence image, points, status, suspension, categories and active scan countdown |
| Offence Select | Active offences, selection, court-case indicator, total points/amount and countdown |
| Fine Confirmation | Selected offences, note, summary, confirmation and issue request |
| Fine Result | Fine outcome, resulting licence state and next action |
| Fine History | Officer-issued fines, status, amount, dates and scan location |
| Profile | Officer, badge, email, division, head, duty location and shift information |
| Settings | Biometrics, auto-lock, password change, about and logout |

#### Divisional Head Screens

| Screen | Main Features |
|---|---|
| Dashboard | Division statistics, officer state, fine/revenue/court metrics and menu |
| Add Traffic Officer | Badge/email/name/password validation and account creation |
| Traffic Officer List | Search, duty status, shift details, shift editing and transfer |
| Assign Shift | Officer selection, existing-shift loading, date/time/location and update/create |
| Court Cases | Overdue/court-case list, payment visibility and verdict flow |
| Revoked Licences | Revocation details, triggering fine and verdict flow |
| Settings | Session profile, biometrics, auto-lock, password change and logout |

#### Police Service and Functional Method Index

- `ApiClient`: `get()`, `post()`, `patch()`, URI construction, JSON/message extraction and typed `ApiException` handling.
- `DeviceService`: `getDeviceId()` and generated fallback device ID.
- `TokenStorage`: `saveSession()`, `getSession()`, `clearSession()`, `getAccessToken()`, `saveDeviceId()`, `getDeviceId()`, `saveBiometricEnabled()`, `getBiometricEnabled()`, JWT-expiry parsing.
- `AuthService`: `login()`, `smartLogin()`, `logout()`, `changePassword()`, `requestForgotPasswordOtp()`, `resetForgottenPassword()`, `requestHeadForgotPasswordOtp()`, `resetHeadForgottenPassword()`, authenticated-session persistence.
- `TrafficFineService`: offence loading, `scanQr()`, `issueFine()`, fine-history loading, payload unwrapping and robust field parsing.
- `FineService`: `getDistrictStatistics()`, court-case loading and `resolveCourtCase()`.
- `OfficerService`: `registerTrafficOfficer()`, division-officer loading, officer-shift loading, `assignShift()`, `updateShift()`, `transferOfficer()`, divisional-head loading.
- QR scanner: `_resolveCameraPermission()`, `_reconcileScanner()`, `_resumeScanner()`, `_stopScannerController()`, `_toggleFlash()`, `_handleScan()`, `_verifySession()`, `_openPreviewWithLicense()`, route and app-lifecycle callbacks.
- Licence preview: `_updateRemaining()`, `_scheduleExpiredDialog()`, `_showExpiredDialog()`, `_openOffenseSelection()`, vehicle-category and licence-detail rendering helpers.
- Offence selection: `_toggleOffense()`, `_selectedOffenses()`, `_totalPoints()`, `_totalAmount()`, `_openConfirmation()`, active-session expiry handling.
- Fine confirmation: `_confirmIssueFine()`, `_issueFine()`, active-session expiry handling.
- Dashboard: `_loadDashboardData()`, `_openScanner()`, `_openHistory()`, `_openProfile()`, `_openSettings()`.
- Fine history: `_loadData()` and status/date presentation.
- Profile: `_loadProfile()` and navigation.
- Traffic Officer settings: `_initBiometricsAndSettings()`, `_toggleBiometric()`, `_updateAutoLockTime()`, `_openChangePassword()`, `_openAbout()`, `_handleLogout()`.
- Divisional dashboard: `_loadStats()`, `_openScreen()` and responsive menu/stat grids.
- Add officer: validation methods and `_handleCreateOfficer()`.
- Assign shift: `_refreshOfficers()`, `_loadSelectedOfficerShift()`, `_findAutoFillShift()`, `_fillFromShift()`, `_selectDateTime()`, `_handleAssignShift()`.
- Officer list: `_refreshOfficers()`, `_loadOfficerShifts()`, `_activeShift()`, `_nextShift()`, `_lastShift()`, `_openAssignShift()`, `_transferOfficer()`.
- Court cases: `_refreshCourtCases()`, `_confirmResolve()`, `_resolveCourtCase()`.
- Revoked licences: `_refreshLicenses()`, `_resolveLicense()`.
- Divisional Head settings: session loading, biometric/auto-lock initialisation, password change and logout.

### Police Data Models

| Model | Responsibility |
|---|---|
| `AuthResponseModel` | JWT and authenticated user payload |
| `FineModel` | Fine/offence/payment/scan-location parsing |
| `DistrictStatisticsModel` | Divisional dashboard statistics |
| `FineIssueResultModel` | Fine-issuance response and resulting licence state |
| `LicenseModel` | Driver and licence details, status, points, suspension, categories and temporary expiry |
| `VehicleCategory` | Vehicle class, dates and restriction/transmission data |
| `OffenseModel` | Offence code, name, points, amount, active and court-case state |
| `OfficerModel` | Officer identity, role, division, duty status and shifts |
| `ShiftInfoModel` / `ShiftModel` | Shift date/time/location and active state |

</details>

<details>
<summary><strong>🗄️ Database model</strong></summary>

### Enums

| Enum | Values |
|---|---|
| `License_Status` | `ACTIVE`, `TEMPORARY`, `SUSPENDED`, `EXPIRED`, `REVOKED` |
| `Fine_Status` | `PENDING`, `PAID`, `OVERDUE`, `COURT_CASE` |
| `Payment_Status` | `PENDING`, `COMPLETED`, `FAILED` |
| `Officer_Role` | `TRAFFIC_OFFICER`, `DIVISIONAL_HEAD` |
| `QrSessionStatus` | `PENDING`, `ACTIVE`, `EXPIRED` |

### Entities

| Entity | Purpose and Main Relationships |
|---|---|
| `DMT_Admin` | Creates/manages driving licences |
| `Police_Admin` | Owns divisions and offence categories |
| `User` | Driver account, OTPs, email/device state and one licence |
| `Driving_License` | Licence identity, status, image, points, suspension flags, fines, categories, QR history and temporary licences |
| `License_Vehicle_Category` | Vehicle class, issue/expiry dates and restriction for one licence |
| `QrSession` | Driver QR connection session and expiry state |
| `QR_Scan_History` | Officer/Driver/licence/head/location audit record |
| `Division` | Police administrative division and its historical heads |
| `Divisional_Head` | Division manager, officers, shifts, fines, QR history and temporary licences |
| `Traffic_Officer` | Enforcement officer, head, shifts, fines, scans and issued temporary licences |
| `Shift` | Officer duty date, start, end, active state and location |
| `Offence_Category` | Offence code, name, points, amount, active state and court-case flag |
| `Fine` | Licence/officer/head-linked fine, due date, status, offences and payment |
| `Fine_Offence` | Many-to-many join between fines and offence categories |
| `Temporary_License` | Time-limited licence issued for eligible unpaid standard fine |
| `Payment` | One payment record per fine |

</details>

<details>
<summary><strong>🔧 Environment variables</strong></summary>

Create local `.env` files from the following templates. Never commit real values.

### Backend — `backend/nest-api/.env`

```dotenv
NODE_ENV=development
PORT=3000

DATABASE_URL=postgresql://<user>:<password>@<host>:5432/<database>?schema=public
JWT_SECRET=<long-random-secret>

EMAIL_USER=<smtp-account>
EMAIL_PASS=<smtp-app-password-or-secret>

AWS_REGION=ap-southeast-1
AWS_S3_BUCKET_NAME=<private-bucket-name>

# Local development only when an IAM role/profile is unavailable.
# Do not set long-lived static keys on production EC2.
AWS_ACCESS_KEY_ID=<local-temporary-key>
AWS_SECRET_ACCESS_KEY=<local-temporary-secret>
```

### Admin Web — `frontend_apps/auto-ledger-frontend/.env.local`

```dotenv
NEXT_PUBLIC_API_URL=http://localhost:3000
NEXT_PUBLIC_S3_HOSTNAME=<bucket-name>.s3.<region>.amazonaws.com
```

### Driver App — `frontend_apps/auto_ledger/.env`

```dotenv
API_URL=http://10.0.2.2:3000
```

### Police App — `frontend_apps/auto_ledger_police/.env`

```dotenv
BASE_URL=http://10.0.2.2:3000
```

### GitLab CI/CD Variables

Configure these as masked/protected project variables under **Settings → CI/CD → Variables**:

| Variable | Purpose |
|---|---|
| `SSH_PRIVATE_KEY` | Dedicated deployment key for EC2 |
| `EC2_IP` | EC2 public IP or DNS name |
| `EC2_USER` | EC2 SSH user |

Recommended additional protected variables for future pipelines:

- `AWS_REGION`
- `AWS_ROLE_ARN` or GitLab OIDC role configuration
- `PRODUCTION_API_URL`
- Release/package credentials when required

</details>

<details>
<summary><strong>✅ Testing and quality</strong></summary>

### Backend Commands

```bash
cd backend/nest-api
npm run format
npm run lint
npm test
npm run test:cov
npm run test:e2e
npm run build
```

### Web Commands

```bash
cd frontend_apps/auto-ledger-frontend
npm run lint
npm run build
```

### Driver App Commands

```bash
cd frontend_apps/auto_ledger
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

### Police App Commands

```bash
cd frontend_apps/auto_ledger_police
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

### Minimum Release Verification

- All builds complete without errors.
- No analyzer/linter warnings accepted without documented justification.
- Prisma migration tested on a clean database and an upgrade copy.
- Authentication tested for all five roles.
- Traffic Officer login tested inside and outside shift time.
- QR session tested for first scan, repeated scan and expiry.
- Fine issuance rejected without a valid active QR session.
- Point thresholds and court-case paths tested.
- Single/bulk payment and Divisional Head resolution tested.
- S3 upload tested with IAM role credentials.
- Amplify custom domain and backend HTTPS tested.
- CI/CD rollback procedure verified.

</details>

<details>
<summary><strong>🏷️ Release management</strong></summary>

Use Semantic Versioning:

```text
vMAJOR.MINOR.PATCH
```

Examples:

- `v1.0.0` — first stable release.
- `v1.1.0` — backward-compatible feature release.
- `v1.1.1` — backward-compatible bug fix.
- `v2.0.0` — breaking API/data/workflow change.

### Release Naming

```text
Release title: Auto Ledger v1.0.0
Git tag:       v1.0.0
```

### Artifact Naming

```text
auto-ledger-driver-v1.0.0+1.apk
auto-ledger-police-v1.0.0+1.apk
auto-ledger-source-v1.0.0.zip
checksums-v1.0.0.txt
```

### Release Link Format

```text
Production Web:
https://www.auto-ledger.tech

Backend API:
https://api.auto-ledger.tech
# Example only. Replace with the actual production API hostname.

Swagger Documentation:
https://api.auto-ledger.tech/api/docs
# Example only. Keep /api/docs if the production Swagger route is unchanged.

GitLab Release Page:
https://gitlab.com/<group>/<project>/-/releases/v1.0.0
# Replace <group>, <project> and v1.0.0.

Driver APK Release Asset:
https://gitlab.com/<group>/<project>/-/releases/v1.0.0/downloads/auto-ledger-driver-v1.0.0+1.apk
# Example direct-asset path. Configure the same direct_asset_path in the GitLab Release.

Police APK Release Asset:
https://gitlab.com/<group>/<project>/-/releases/v1.0.0/downloads/auto-ledger-police-v1.0.0+1.apk
# Example direct-asset path. Configure the same direct_asset_path in the GitLab Release.

Latest Driver APK:
https://gitlab.com/<group>/<project>/-/releases/permalink/latest/downloads/auto-ledger-driver-latest.apk
# Optional permanent latest-release link; create the matching release asset link.

Latest Police APK:
https://gitlab.com/<group>/<project>/-/releases/permalink/latest/downloads/auto-ledger-police-latest.apk
# Optional permanent latest-release link; create the matching release asset link.
```

### Release Notes Template

```markdown
# Auto Ledger v1.0.0

## Highlights
- Describe the main user-visible improvements.

## Driver App
- Added/changed/fixed items.

## Police App
- Added/changed/fixed items.

## Admin Web Portal
- Added/changed/fixed items.

## Backend and Database
- API, migration and business-rule changes.

## Deployment
- EC2, Amplify, S3 or CI/CD changes.

## Breaking Changes
- None, or clearly list required client/migration actions.

## Database Migration
- Migration command and rollback notes.

## Known Issues
- List remaining limitations.

## Downloads
- Driver APK
- Police APK
- Source archive
- Checksums
```

### Release Checklist

- Update package versions.
- Update changelog/release notes.
- Run all quality checks.
- Create and review production database migration.
- Build signed mobile artifacts.
- Generate SHA-256 checksums.
- Create protected Git tag.
- Publish GitLab Release and assets.
- Deploy backend and web.
- Perform smoke tests.
- Confirm monitoring and rollback readiness.

</details>

<details>
<summary><strong>🔗 Official technical references</strong></summary>

- AWS Amplify Hosting: https://docs.aws.amazon.com/amplify/latest/userguide/welcome.html
- Deploy Next.js to Amplify: https://docs.aws.amazon.com/amplify/latest/userguide/getting-started-next.html
- Amplify custom domains: https://docs.aws.amazon.com/amplify/latest/userguide/custom-domains.html
- IAM roles for EC2: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html
- AWS SDK credentials from an EC2 IAM role: https://docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/loading-node-credentials-iam.html
- S3 presigned uploads: https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html
- GitLab deployment to AWS: https://docs.gitlab.com/ci/cloud_deployment/
- GitLab CI/CD SSH keys: https://docs.gitlab.com/ci/jobs/ssh_keys/
- GitLab Releases: https://docs.gitlab.com/user/project/releases/
- NestJS deployment: https://docs.nestjs.com/deployment
- Next.js deployment: https://nextjs.org/docs/app/getting-started/deploying
- Flutter deployment: https://docs.flutter.dev/deployment

---

<div align="center">

**Auto Ledger — connected licensing, accountable enforcement and transparent fine management.**

</div>

</details>

---

<a id="contribution-workflow"></a>
## 🤝 Contribution Workflow

### Branch Strategy

```text
main                 Production-ready code
└── development      Integration branch
    ├── feature/...  New functionality
    ├── fix/...      Bug fixes
    ├── refactor/... Internal improvements
    └── docs/...     Documentation updates
```

### Commit Style

Use Conventional Commits:

```text
feat(police): add QR session expiry handling
fix(backend): preserve licence status after payment
docs(readme): document EC2 IAM role deployment
refactor(driver): simplify secure session restore
test(fines): cover 24, 50 and 100 point thresholds
```

### Merge Request Requirements

- Clear problem statement and solution summary.
- Linked issue/task.
- Scope limited to the requested change.
- Screenshots for UI changes without exposing personal data.
- API contract and migration notes for backend changes.
- Test evidence.
- No secrets, credentials, personal emails, NICs or production data.
- At least one teammate review.
- Successful CI/CD checks before merge.

### Code Ownership Guidance

- Backend business-rule changes require backend and database review.
- Mobile API model changes must be checked against backend response contracts.
- Admin changes must be tested for both DMT and Police roles.
- Prisma migrations must be reviewed for data safety and rollback impact.
- Infrastructure changes must include deployment and recovery instructions.

---

<a id="team"></a>
## 🏆 Team

<div align="center">

### Built by the Auto Ledger Team

<img src="https://img.shields.io/badge/Venusha_Thishan-Owner_%26_Core_Contributor-7C3AED?style=for-the-badge" alt="Venusha Thishan — Owner and Core Contributor">

<br><br>

<img src="https://img.shields.io/badge/Chamira_Hashan-Core_Contributor-16A34A?style=for-the-badge" alt="Chamira Hashan — Core Contributor">

<img src="https://img.shields.io/badge/Maheema_Vihangi-Core_Contributor-0A66C2?style=for-the-badge" alt="Maheema Vihangi — Core Contributor">

<img src="https://img.shields.io/badge/Thiloka_Indhuwari-Core_Contributor-EA580C?style=for-the-badge" alt="Thiloka Indhuwari — Core Contributor">

<br><br>

**Ownership · Collaboration · Engineering · Quality · Delivery**

</div>

---

<a id="licence"></a>
## 📄 Licence

This project is distributed under the [MIT License](LICENSE).

Copyright © 2026 Auto Ledger contributors.

---

<div align="center">

**Auto Ledger — connected licensing, accountable enforcement and transparent fine management.**

</div>
