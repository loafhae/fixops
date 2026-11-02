from datetime import datetime, timezone, timedelta
from backend.app.db.session import engine, SessionLocal, Base
from backend.app.models.user import User, UserRole
from backend.app.models.ticket import Ticket, TicketCategory, TicketPriority, TicketStatus
from backend.app.models.audit_log import AuditLog
from backend.app.core.security import get_password_hash

def seed_database():
    print("Dropping and recreating database tables...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # Check if users already seeded
        existing_admin = db.query(User).filter(User.email == "admin@fixops.local").first()
        if existing_admin:
            print("Database already contains seed data.")
            return

        print("Seeding initial users...")
        admin = User(
            email="admin@fixops.local",
            full_name="System Administrator",
            hashed_password=get_password_hash("Admin123!"),
            role=UserRole.ADMIN,
            department="IT Infrastructure & SysAdmin",
            is_active=True
        )

        tech = User(
            email="tech@fixops.local",
            full_name="Alex Rivera (Lead Technician)",
            hashed_password=get_password_hash("Tech123!"),
            role=UserRole.TECHNICIAN,
            department="Facilities & Maintenance",
            is_active=True
        )

        user = User(
            email="user@fixops.local",
            full_name="Joyce Ambuyo (Staff/Student)",
            hashed_password=get_password_hash("User123!"),
            role=UserRole.USER,
            department="College of Information Technology",
            is_active=True
        )

        db.add_all([admin, tech, user])
        db.commit()
        db.refresh(admin)
        db.refresh(tech)
        db.refresh(user)

        print("Seeding sample facility tickets...")
        tickets = [
            Ticket(
                ticket_number="TKT-2026-0001",
                title="Exposed live electrical wiring behind podium",
                description="Conduit came loose exposing copper wires near the instructor's podium. Poses an electric shock hazard for classes.",
                building="IT Building",
                floor_room="3rd Floor, Lab 304",
                category=TicketCategory.ELECTRICAL,
                priority=TicketPriority.CRITICAL,
                status=TicketStatus.UNDER_REVIEW,
                reported_by_id=user.id,
                assigned_to_id=tech.id,
                created_at=datetime.now(timezone.utc) - timedelta(hours=3),
                updated_at=datetime.now(timezone.utc) - timedelta(hours=1)
            ),
            Ticket(
                ticket_number="TKT-2026-0002",
                title="Pipe leakage flooding corridor",
                description="Water pipe under the sink in the 1st floor restroom is leaking heavily and water is pooling into the main hallway.",
                building="Main Academic Hall",
                floor_room="1st Floor, Restroom A",
                category=TicketCategory.PLUMBING,
                priority=TicketPriority.HIGH,
                status=TicketStatus.IN_PROGRESS,
                reported_by_id=user.id,
                assigned_to_id=tech.id,
                created_at=datetime.now(timezone.utc) - timedelta(days=1),
                updated_at=datetime.now(timezone.utc) - timedelta(hours=5)
            ),
            Ticket(
                ticket_number="TKT-2026-0003",
                title="AC unit blowing warm air & loud vibration",
                description="The split-type air conditioner in room 202 is making rattling noises and no longer cooling the room.",
                building="Engineering Complex",
                floor_room="2nd Floor, Room 202",
                category=TicketCategory.HVAC,
                priority=TicketPriority.MEDIUM,
                status=TicketStatus.SUBMITTED,
                reported_by_id=user.id,
                created_at=datetime.now(timezone.utc) - timedelta(days=2),
                updated_at=datetime.now(timezone.utc) - timedelta(days=2)
            ),
            Ticket(
                ticket_number="TKT-2026-0004",
                title="Broken armrest on student desk row 4",
                description="Desk armrest detached with jagged plastic edge. Needs replacement or repair.",
                building="General Education Wing",
                floor_room="Ground Floor, Room 105",
                category=TicketCategory.FURNITURE,
                priority=TicketPriority.LOW,
                status=TicketStatus.RESOLVED,
                reported_by_id=user.id,
                assigned_to_id=tech.id,
                resolution_notes="Replaced broken armrest bracket with new spare part. Checked stability.",
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
                details=f"Ticket #{tickets[3].ticket_number} marked RESOLVED with repair notes.",
                ip_address="192.168.1.50",
                timestamp=datetime.now(timezone.utc) - timedelta(hours=2)
            ),
        ]
        db.add_all(logs)
        db.commit()

        print("Database seeded successfully with default accounts:")
        print("  Admin:      admin@fixops.local / Admin123!")
        print("  Technician: tech@fixops.local  / Tech123!")
        print("  User:       user@fixops.local  / User123!")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()

