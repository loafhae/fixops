# FIXOPS: Facility Issue Reporting & Maintenance System
**System Administration (BSIT 4B) Project**

* **Course:** System Administration (BSIT 4B)
* **Team Members:**
  * Joyce Bernadeth S. Ambuyo
  * John Laurence A. Lagapa
  * Sunday Le'Chaim L. Nadonga
  * Jay Ynewson Suarilla

---

## 🌟 Overview

**FIXOPS** is a centralized facility issue reporting and maintenance management platform bridging practical software engineering with real-world system administration. It replaces informal, scattered reporting channels (verbal talks, lost group chats, paper forms) with a structured digital intake workflow, real-time ticket triage, photo evidence tracking, and an immutable activity audit trail.

---

## 🏗️ Architecture & Technology Stack

* **Backend Service (Python & FastAPI):**
  * High-performance asynchronous REST API.
  * **Role-Based Access Control (RBAC):** Tiered roles (`USER`, `TECHNICIAN`, `ADMIN`) protected with JWT Bearer tokens and BCrypt salted password hashing.
  * **Local Server & Network Hosting:** Binds to `0.0.0.0:8000` to allow access across the organizational Local Area Network (LAN) for physical mobile devices and web browsers.
  * **Media Storage Management:** Safe server-side handling and static hosting of photo evidence under `/uploads/tickets/`.
  * **Activity Audit Trail:** Real-time logging of user logins, role changes, and ticket status updates with IP address and timestamp recording.
  * **Database Layer:** SQLite (local zero-configuration) with SQLAlchemy ORM, easily switchable to PostgreSQL or MySQL.
  * **Interactive API Documentation:** Auto-generated Swagger UI at `http://127.0.0.1:8000/api/v1/docs`.

* **Frontend Client (Flutter Multiplatform):**
  * **Cross-Platform Delivery:** Runs natively on **Mobile** (Android/iOS) and **Web** (Chrome, Edge, Desktop).
  * **Adaptive Responsive UI:**
    * **Web / Desktop ($\ge 900$px):** Full-screen dashboard with navigation sidebar, analytics cards, triage tables, audit trail viewer, and RBAC user management.
    * **Mobile Phone ($< 900$px):** Clean single-handed reporting interface with bottom navigation and quick camera/photo attachments.

---

## 🚀 Quick Start Guide

### Prerequisites
* Python 3.10+
* Flutter SDK (3.24+)
* Google Chrome (for web testing) or Android device / emulator

### Step 1: Start Backend Server
Double-click `run_backend.bat` or run:
```powershell
cd backend
.\venv\Scripts\activate
$env:PYTHONPATH=".."
uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```
The backend API is now running at:
* Swagger API Docs: `http://127.0.0.1:8000/api/v1/docs`
* Health Check: `http://127.0.0.1:8000/api/health`

### Step 2: Seed Database (Included in setup)
To re-seed sample users, tickets, and audit logs at any time:
```powershell
$env:PYTHONPATH="."
.\backend\venv\Scripts\python.exe backend\seed.py
```

### Step 3: Run Flutter Web Application
Double-click `run_web.bat` or run:
```powershell
cd frontend
flutter run -d chrome
```

### Step 4: Run on Android (Mobile)
Ensure an Android emulator is running or a device is connected via USB:
```powershell
cd frontend
flutter run -d android
```

---

## 🔑 Default Demo Accounts

The database comes pre-seeded with simple demo accounts for testing and defense presentations:

| Role | Username / Email | Password | Permissions & Views |
| :--- | :--- | :--- | :--- |
| **System Administrator** | `admin` *(or `admin@fixops.local`)* | `admin` | Full access: Dashboard KPIs, User Management & RBAC, Activity Audit Trail, Full Ticket Triage |
| **Maintenance Technician** | `tech` *(or `tech@fixops.local`)* | `tech` | Work Orders: Claim tickets, update status (In Progress / Resolved), log resolution proof |
| **Student / Staff (End-User)** | `user` *(or `user@fixops.local`)* | `user` | Reporting: Submit maintenance tickets, attach photo evidence, track personal ticket status |

*(Quick-login chips are also provided on the sign-in screen to autofill these credentials with a single tap).*

---

## 📁 Repository Directory Structure

```text
Facili-Ops/
├── backend/                  # FastAPI Application
│   ├── app/
│   │   ├── api/              # REST Endpoints (auth, tickets, users, audit_logs, stats)
│   │   ├── core/             # Security (JWT, bcrypt), config & paths
│   │   ├── db/               # SQLAlchemy engine & session setup
│   │   ├── models/           # DB Models (User, Ticket, Attachment, AuditLog)
│   │   └── schemas/          # Pydantic Request & Response DTOs
│   ├── logs/                 # System and audit log files
│   ├── uploads/              # Local server photo evidence repository
│   ├── main.py               # FastAPI application entry point
│   ├── requirements.txt      # Python dependencies
│   └── seed.py               # Database seeder script
│
├── frontend/                 # Pure Flutter Multiplatform App (Mobile + Web)
│   ├── lib/
│   │   ├── core/             # API client, colors, config
│   │   ├── models/           # Dart models (User, Ticket, AuditLog)
│   │   ├── providers/        # State Management (Auth, Tickets, Admin)
│   │   ├── views/            # UI Views (Login, Register, Dashboard, Tickets, Audit, Users)
│   │   └── main.dart         # Entry point & responsive routing
│   └── pubspec.yaml          # Flutter dependencies
│
├── run_backend.bat           # One-click Windows backend launcher
├── run_web.bat               # One-click Windows Flutter web launcher
└── README.md                 # System documentation
```
