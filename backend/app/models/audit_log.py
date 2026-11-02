import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.db.session import Base

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    user_email = Column(String, nullable=True)
    action = Column(String, nullable=False)  # e.g., TICKET_CREATED, STATUS_UPDATED, ASSIGNED_TECH, USER_ROLE_CHANGED
    target_ticket_id = Column(String, ForeignKey("tickets.id", ondelete="SET NULL"), nullable=True)
    details = Column(Text, nullable=True)
    ip_address = Column(String, nullable=True)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="audit_logs")
    ticket = relationship("Ticket", back_populates="audit_logs")

