import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.db.session import Base

class TicketCategory:
    ELECTRICAL = "ELECTRICAL"
    PLUMBING = "PLUMBING"
    STRUCTURAL = "STRUCTURAL"
    HVAC = "HVAC"
    FURNITURE = "FURNITURE"
    SAFETY_HAZARD = "SAFETY_HAZARD"
    OTHER = "OTHER"

class TicketPriority:
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

class TicketStatus:
    SUBMITTED = "SUBMITTED"
    UNDER_REVIEW = "UNDER_REVIEW"
    IN_PROGRESS = "IN_PROGRESS"
    RESOLVED = "RESOLVED"
    CANCELLED = "CANCELLED"

class Ticket(Base):
    __tablename__ = "tickets"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    ticket_number = Column(String, unique=True, index=True, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    building = Column(String, nullable=False)
    floor_room = Column(String, nullable=False)
    category = Column(String, default=TicketCategory.OTHER, nullable=False)
    priority = Column(String, default=TicketPriority.MEDIUM, nullable=False)
    status = Column(String, default=TicketStatus.SUBMITTED, nullable=False)

    reported_by_id = Column(String, ForeignKey("users.id"), nullable=False)
    assigned_to_id = Column(String, ForeignKey("users.id"), nullable=True)

    resolution_notes = Column(Text, nullable=True)
    resolved_at = Column(DateTime, nullable=True)

    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    reporter = relationship("User", foreign_keys=[reported_by_id], back_populates="reported_tickets")
    technician = relationship("User", foreign_keys=[assigned_to_id], back_populates="assigned_tickets")
    attachments = relationship("Attachment", back_populates="ticket", cascade="all, delete-orphan")
    audit_logs = relationship("AuditLog", back_populates="ticket")

