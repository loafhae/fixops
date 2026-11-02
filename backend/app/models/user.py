import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.orm import relationship
from backend.app.db.session import Base

class UserRole:
    ADMIN = "ADMIN"
    TECHNICIAN = "TECHNICIAN"
    USER = "USER"

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default=UserRole.USER, nullable=False)  # ADMIN, TECHNICIAN, USER
    department = Column(String, default="General", nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    reported_tickets = relationship("Ticket", back_populates="reporter", foreign_keys="Ticket.reported_by_id")
    assigned_tickets = relationship("Ticket", back_populates="technician", foreign_keys="Ticket.assigned_to_id")
    audit_logs = relationship("AuditLog", back_populates="user")

