import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.db.session import Base

class Attachment(Base):
    __tablename__ = "ticket_attachments"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    ticket_id = Column(String, ForeignKey("tickets.id", ondelete="CASCADE"), nullable=False)
    file_path = Column(String, nullable=False)
    file_name = Column(String, nullable=False)
    file_type = Column(String, default="IMAGE_EVIDENCE")  # IMAGE_EVIDENCE, RESOLUTION_PROOF
    file_size_bytes = Column(Integer, default=0)
    uploaded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)

    ticket = relationship("Ticket", back_populates="attachments")

