from datetime import datetime, timezone, timedelta
from backend.app.db.session import engine, SessionLocal, Base
from backend.app.models.user import User, UserRole
from backend.app.models.ticket import Ticket, TicketCategory, TicketPriority, TicketStatus
from backend.app.models.audit_log import AuditLog
from backend.app.core.security import get_password_hash


def refresh_legacy_demo_tickets(db):
    updates = {
        "TKT-2026-0001": (
            "Exposed live electrical wiring behind podium",
            "Network switch offline in Lab 304",
            "The lab access switch is unresponsive, leaving workstations without wired network access to campus services.",
            "NETWORK",
            "3rd Floor, Lab 304",
        ),
        "TKT-2026-0002": (
            "Pipe leakage flooding corridor",
            "Intermittent Wi-Fi across Main Academic Hall",
            "Users are repeatedly disconnected from campus Wi-Fi in the hall, interrupting access to learning and work systems.",
            "NETWORK",
            "1st Floor, East Wing",
        ),
        "TKT-2026-0003": (
            "AC unit blowing warm air & loud vibration",
            "Workstation will not boot in Room 202",
            "The workstation powers on but does not complete startup or reach the operating system login screen.",
            "HARDWARE",
            "2nd Floor, Room 202",
        ),
        "TKT-2026-0004": (
            "Broken armrest on student desk row 4",
            "Student account locked after password reset",
            "The student cannot sign in to campus services after completing a password reset.",
            "ACCOUNT_ACCESS",
            "Ground Floor, Help Desk",
        ),
    }

    for ticket_number, values in updates.items():
        old_title, title, description, category, floor_room = values
        ticket = db.query(Ticket).filter(Ticket.ticket_number == ticket_number).first()
        if ticket and ticket.title == old_title:
            ticket.title = title
            ticket.description = description
            ticket.category = category
            ticket.floor_room = floor_room
            if ticket_number == "TKT-2026-0004":
                ticket.resolution_notes = (
                    "Cleared the account lockout and confirmed the student could sign in."
                )


def seed_database():
    print("Dropping and recreating database tables...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # Check if users already seeded
        # Update passwords if users already exist
        existing_admin = db.query(User).filter(User.email == "admin@fixops.local").first()
        existing_tech = db.query(User).filter(User.email == "tech@fixops.local").first()
        existing_user = db.query(User).filter(User.email == "user@fixops.local").first()

        if existing_admin and existing_tech and existing_user:
            existing_admin.hashed_password = get_password_hash("admin")
            existing_tech.hashed_password = get_password_hash("tech")
            existing_user.hashed_password = get_password_hash("user")
            refresh_legacy_demo_tickets(db)
            db.commit()
            print("Updated demo accounts and legacy sample reports to IT support issues.")
            return

        print("Seeding initial users...")
        admin = User(
            email="admin@fixops.local",
            full_name="System Administrator",
            hashed_password=get_password_hash("admin"),
            role=UserRole.ADMIN,
            department="IT Infrastructure & SysAdmin",
            is_active=True
        )

        tech = User(
            email="tech@fixops.local",
            full_name="Alex Rivera (Lead Technician)",
            hashed_password=get_password_hash("tech"),
            role=UserRole.TECHNICIAN,
            department="IT Support",
            is_active=True
        )

        user = User(
            email="user@fixops.local",
            full_name="Joyce Ambuyo (Staff/Student)",
            hashed_password=get_password_hash("user"),
            role=UserRole.USER,
            department="College of Information Technology",
            is_active=True
        )

        db.add_all([admin, tech, user])
        db.commit()
        db.refresh(admin)
        db.refresh(tech)
        db.refresh(user)

        print("Seeding sample IT support tickets...")
        tickets = [
            Ticket(
                ticket_number="TKT-2026-0001",
                title="Network switch offline in Lab 304",
                description="The lab access switch is unresponsive, leaving workstations without wired network access to campus services.",
                building="IT Building",
                floor_room="3rd Floor, Lab 304",
                category=TicketCategory.NETWORK,
                priority=TicketPriority.CRITICAL,
                status=TicketStatus.UNDER_REVIEW,
                reported_by_id=user.id,
                assigned_to_id=tech.id,
                created_at=datetime.now(timezone.utc) - timedelta(hours=3),
                updated_at=datetime.now(timezone.utc) - timedelta(hours=1)
            ),
            Ticket(
                ticket_number="TKT-2026-0002",
                title="Intermittent Wi-Fi across Main Academic Hall",
                description="Users are repeatedly disconnected from campus Wi-Fi in the hall, interrupting access to learning and work systems.",
                building="Main Academic Hall",
                floor_room="1st Floor, East Wing",
                category=TicketCategory.NETWORK,
                priority=TicketPriority.HIGH,
                status=TicketStatus.IN_PROGRESS,
                reported_by_id=user.id,
                assigned_to_id=tech.id,
                created_at=datetime.now(timezone.utc) - timedelta(days=1),
                updated_at=datetime.now(timezone.utc) - timedelta(hours=5)
            ),
            Ticket(
                ticket_number="TKT-2026-0003",
                title="Workstation will not boot in Room 202",
                description="The workstation powers on but does not complete startup or reach the operating system login screen.",
                building="Engineering Complex",
                floor_room="2nd Floor, Room 202",
                category=TicketCategory.HARDWARE,
                priority=TicketPriority.MEDIUM,
                status=TicketStatus.SUBMITTED,
                reported_by_id=user.id,
                created_at=datetime.now(timezone.utc) - timedelta(days=2),
                updated_at=datetime.now(timezone.utc) - timedelta(days=2)
            ),
            Ticket(
                ticket_number="TKT-2026-0004",
                title="Student account locked after password reset",
                description="The student cannot sign in to campus services after completing a password reset.",
                building="General Education Wing",
                floor_room="Ground Floor, Help Desk",
                category=TicketCategory.ACCOUNT_ACCESS,
                priority=TicketPriority.LOW,
                status=TicketStatus.RESOLVED,
                reported_by_id=user.id,
                assigned_to_id=tech.id,
                resolution_notes="Cleared the account lockout and confirmed the student could sign in.",
                resolved_at=datetime.now(timezone.utc) - timedelta(hours=2),
                created_at=datetime.now(timezone.utc) - timedelta(days=4),
                updated_at=datetime.now(timezone.utc) - timedelta(hours=2)
            ),
        ]

        db.add_all(tickets)
        db.commit()

        print("Seeding initial audit logs...")
        logs = [
            AuditLog(
                user_id=admin.id,
                user_email=admin.email,
                action="SYSTEM_INIT",
                details="Initial database seed and system setup completed.",
                ip_address="127.0.0.1",
                timestamp=datetime.now(timezone.utc) - timedelta(days=5)
            ),
            AuditLog(
                user_id=user.id,
                user_email=user.email,
                action="TICKET_CREATED",
                target_ticket_id=tickets[0].id,
                details=f"Ticket #{tickets[0].ticket_number} created with priority CRITICAL in {tickets[0].building}",
                ip_address="192.168.1.105",
                timestamp=datetime.now(timezone.utc) - timedelta(hours=3)
            ),
            AuditLog(
                user_id=tech.id,
                user_email=tech.email,
                action="TICKET_ASSIGNED",
                target_ticket_id=tickets[0].id,
                details=f"Lead technician claimed Ticket #{tickets[0].ticket_number}",
                ip_address="192.168.1.50",
                timestamp=datetime.now(timezone.utc) - timedelta(hours=1)
            ),
            AuditLog(
                user_id=tech.id,
                user_email=tech.email,
                action="TICKET_STATUS_UPDATED",
                target_ticket_id=tickets[3].id,
                details=f"Ticket #{tickets[3].ticket_number} marked RESOLVED with support notes.",
                ip_address="192.168.1.50",
                timestamp=datetime.now(timezone.utc) - timedelta(hours=2)
            ),
        ]
        db.add_all(logs)
        db.commit()

        print("Database seeded successfully with simple default accounts:")
        print("  Admin:      admin / admin  (or admin@fixops.local)")
        print("  Technician: tech  / tech   (or tech@fixops.local)")
        print("  User:       user  / user   (or user@fixops.local)")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
