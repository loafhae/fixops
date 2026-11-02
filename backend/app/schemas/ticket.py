from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel
from backend.app.schemas.user import UserResponse

class AttachmentResponse(BaseModel):
    id: str
    file_path: str
    file_name: str
    file_type: str
    file_size_bytes: int
    uploaded_at: datetime

    class Config:
        from_attributes = True

class TicketBase(BaseModel):
    title: str
    description: str
    building: str
    floor_room: str
    category: str = "OTHER"
    priority: str = "MEDIUM"

class TicketCreate(TicketBase):
    pass

class TicketStatusUpdate(BaseModel):
    status: str
    resolution_notes: Optional[str] = None

class TicketAssign(BaseModel):
    technician_id: str

class TicketResponse(TicketBase):
    id: str
    ticket_number: str
    status: str
    reported_by_id: str
    assigned_to_id: Optional[str] = None
    resolution_notes: Optional[str] = None
    resolved_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    reporter: Optional[UserResponse] = None
    technician: Optional[UserResponse] = None
    attachments: List[AttachmentResponse] = []

    class Config:
        from_attributes = True

class TicketStatsResponse(BaseModel):
    total_tickets: int
    open_tickets: int
    resolved_tickets: int
    critical_tickets: int
    by_category: dict[str, int]
    by_priority: dict[str, int]
    by_status: dict[str, int]

