# Buoy ERP 🚢

A modern, full-stack Enterprise Resource Planning (ERP) application designed for manufacturing and enterprise operations. Built with a high-contrast glassmorphic Flutter frontend, a Node.js/Express REST backend, and Supabase (PostgreSQL) for scalable cloud data management and authentication.

---

## 🌟 Key Features

- **📊 Centralized Dashboard**: Real-time business metrics, low stock indicators, production statuses, and operational summaries.
- **👥 Employee & HR Payroll**:
  - Employee directory with full profile details and role management.
  - Daily attendance tracking and timesheet management.
  - Automated payroll calculation and salary slip generation.
- **📦 Inventory & Stock Control**:
  - Item catalog with SKU, category, quantity, and unit cost tracking.
  - Automated low-stock thresholds with proactive alert notifications.
- **🏭 Production Tracking**:
  - Batch tracking, manufacturing logs, and stage progression.
  - Production schedules and status management.
- **🔔 Notification Center**:
  - Multi-channel notification support: Local In-App alerts and Firebase Cloud Messaging (FCM).
  - Configurable alert filters (urgent, inventory, payroll, reminders).
- **🛡️ Web Admin Portal**:
  - Lightweight server-rendered web dashboard (`/admin`) powered by EJS and Express.
  - Admin toggle for user registration and system control.
- **🎨 Glassmorphic UI**:
  - Custom frosted glass container components (`GlassContainer`, `LiquidGlassToggle`).
  - Dark and high-contrast theme optimized for tablets and mobile devices.

---

## 🏗️ Architecture & Tech Stack

```
Buoy ERP Solution
├── Frontend (Flutter App)
│   ├── State Management & Clean Architecture
│   ├── Custom Glassmorphism UI Components
│   └── Cross-Platform: Android, iOS, Web, Windows, macOS, Linux
│
├── Backend (Node.js & Express)
│   ├── RESTful APIs for Auth, Profile, Employees, Items, Production, Dashboard
│   ├── Server-Side Admin Panel (EJS)
│   └── Firebase Admin SDK (Cloud Messaging)
│
└── Database & Auth (Supabase / PostgreSQL)
    ├── Row Level Security (RLS)
    └── Automated Database Migrations & Schemas
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.35+)
- [Node.js](https://nodejs.org/) (v18+) & `npm`
- [Supabase](https://supabase.com/) project account

---

### 1. Database Setup (Supabase)

Execute the following SQL setup scripts in your Supabase SQL Editor in order:

1. `supabase_setup_employees.sql` — Creates the `employees` and `attendance` tables with RLS policies.
2. `supabase_setup_payroll.sql` — Sets up payroll records, salary bands, and payment statuses.
3. `supabase_setup_production.sql` — Configures manufacturing stages, inventory batches, and production schedules.

---

### 2. Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create your `.env` configuration file from the template:
   ```bash
   cp .env.example .env
   ```
   Configure the following variables in `.env`:
   ```env
   PORT=3000
   NODE_ENV=development
   SUPABASE_URL=https://your-supabase-project.supabase.co
   SUPABASE_PUBLISHABLE_KEY=your-supabase-publishable-key
   SUPABASE_SECRET_KEY=your-supabase-service-role-key
   ```

4. Start the backend development server:
   ```bash
   npm run dev
   ```
   The backend API will be available at `http://localhost:3000/api` and the Admin Portal at `http://localhost:3000/admin`.

---

### 3. Frontend Setup (Flutter)

1. Return to the root project directory:
   ```bash
   flutter pub get
   ```

2. Configure backend connection in `lib/core/config/api_config.dart`:
   - Set `isProduction = false` for local development (`http://localhost:3000/api` or local LAN IP).
   - Set `isProduction = true` for cloud deployments (e.g., Vercel / Render).

3. Run the app:
   ```bash
   # Run in Chrome (Web)
   flutter run -d chrome

   # Or run on connected Android/iOS device
   flutter run
   ```

> 💡 **Quick Start for Windows**: Run `start.bat` from the root directory to launch both the backend server and Flutter Web simultaneously.

---

## 📂 Project Structure

```
buoy-erp/
├── assets/                    # Icons, illustrations, and images
├── backend/                   # Node.js/Express API & Admin Portal
│   ├── config/                # Supabase & Firebase service configs
│   ├── controllers/           # Route handlers (auth, employee, item, production)
│   ├── middleware/            # JWT authentication middleware
│   ├── routes/                # Express API endpoints
│   ├── views/                 # EJS templates for the Admin dashboard
│   ├── server.js              # Application entry point
│   └── vercel.json            # Vercel deployment configuration
├── lib/                       # Flutter Application
│   ├── app/                   # App root, routing, theme definitions
│   ├── core/                  # Shared widgets, services, configs, helpers
│   ├── features/              # Feature modules (Auth, Dashboard, HR, Inventory, Production)
│   └── main.dart              # Flutter entry point
├── supabase_setup_*.sql       # Supabase database initialization scripts
├── start.bat                  # One-click startup script for dev environment
└── pubspec.yaml               # Flutter package configuration
```

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. **Fork** the repository
2. **Create your feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'feat: add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request** to `kavypatel03/buoy-erp-main:main`

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) or project owner terms.
