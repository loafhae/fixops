from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: str
    ticket_id: Optional[str] = None
    event_type: str
    message: str
    created_at: datetime
    read_at: Optional[datetime] = None

    class Config:
        from_attributes = True
