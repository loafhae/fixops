import os
import uuid
import aiofiles
from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File, Form, Request
from sqlalchemy.orm import Session
from sqlalchemy import desc

from backend.app.core.config import settings
from backend.app.db.session import get_db
from backend.app.models.user import User, UserRole
from backend.app.models.ticket import Ticket, TicketCategory, TicketPriority, TicketStatus
from backend.app.models.attachment import Attachment
from backend.app.schemas.ticket import (
    TicketCreate,
    TicketResponse,
    TicketStatusUpdate,
    TicketAssign,
    AttachmentResponse
)
from backend.app.api.deps import get_current_user, require_roles, log_audit_event

router = APIRouter(prefix="/tickets", tags=["Tickets"])

def generate_ticket_number(db: Session) -> str:
    year = datetime.now().year
    count = db.query(Ticket).count() + 1
    return f"TKT-{year}-{count:04d}"

@router.get("/", response_model=List[TicketResponse])
def get_tickets(
    status_filter: Optional[str] = Query(None, alias="status"),
    priority_filter: Optional[str] = Query(None, alias="priority"),
    category_filter: Optional[str] = Query(None, alias="category"),
    search: Optional[str] = Query(None),
    my_tickets_only: bool = Query(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Ticket)

    # Standard users only see their own tickets unless they are technician or admin
    if current_user.role == UserRole.USER or my_tickets_only:
        query = query.filter(Ticket.reported_by_id == current_user.id)
    
    if status_filter:
        query = query.filter(Ticket.status == status_filter.upper())
    if priority_filter:
        query = query.filter(Ticket.priority == priority_filter.upper())
    if category_filter:
        query = query.filter(Ticket.category == category_filter.upper())
    
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            (Ticket.title.ilike(search_pattern)) |
            (Ticket.ticket_number.ilike(search_pattern)) |
            (Ticket.building.ilike(search_pattern)) |
            (Ticket.floor_room.ilike(search_pattern))
        )
    
    return query.order_by(desc(Ticket.created_at)).all()

@router.post("/", response_model=TicketResponse, status_code=status.HTTP_201_CREATED)
def create_ticket(
    ticket_in: TicketCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    ticket_no = generate_ticket_number(db)
    new_ticket = Ticket(
        ticket_number=ticket_no,
        title=ticket_in.title.strip(),
        description=ticket_in.description.strip(),
        building=ticket_in.building.strip(),
        floor_room=ticket_in.floor_room.strip(),
        category=ticket_in.category.upper(),
        priority=ticket_in.priority.upper(),
        status=TicketStatus.SUBMITTED,
        reported_by_id=current_user.id
    )
    db.add(new_ticket)
    db.commit()
    db.refresh(new_ticket)

    log_audit_event(
        db=db,
        action="TICKET_CREATED",
        user=current_user,
        target_ticket_id=new_ticket.id,
        details=f"Ticket #{new_ticket.ticket_number} created with priority {new_ticket.priority} in {new_ticket.building}",
        request=request
    )

    return new_ticket

@router.get("/{ticket_id}", response_model=TicketResponse)
def get_ticket(
    ticket_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found.")
    
    # Regular users can only inspect their own tickets
    if current_user.role == UserRole.USER and ticket.reported_by_id != current_user.id:
        raise HTTPException(status_code=403, detail="You do not have permission to view this ticket.")
    
    return ticket

@router.patch("/{ticket_id}/status", response_model=TicketResponse)
def update_ticket_status(
    ticket_id: str,
    status_update: TicketStatusUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.ADMIN, UserRole.TECHNICIAN]))
):
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found.")
    
    prev_status = ticket.status
    ticket.status = status_update.status.upper()
    
    if status_update.resolution_notes:
        ticket.resolution_notes = status_update.resolution_notes
    
    if ticket.status == TicketStatus.RESOLVED:
        ticket.resolved_at = datetime.now(timezone.utc)
        if not ticket.assigned_to_id:
            ticket.assigned_to_id = current_user.id
    
    db.commit()
    db.refresh(ticket)

    log_audit_event(
        db=db,
        action="TICKET_STATUS_UPDATED",
        user=current_user,
        target_ticket_id=ticket.id,
        details=f"Ticket #{ticket.ticket_number} status changed from {prev_status} to {ticket.status}",
        request=request
    )

    return ticket

@router.patch("/{ticket_id}/assign", response_model=TicketResponse)
def assign_technician(
    ticket_id: str,
    assign_in: TicketAssign,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.ADMIN, UserRole.TECHNICIAN]))
):
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found.")
    
    tech = db.query(User).filter(User.id == assign_in.technician_id).first()
    if not tech or tech.role not in [UserRole.TECHNICIAN, UserRole.ADMIN]:
        raise HTTPException(status_code=400, detail="Assigned user must be a technician or admin.")
    
    ticket.assigned_to_id = tech.id
    if ticket.status == TicketStatus.SUBMITTED:
        ticket.status = TicketStatus.UNDER_REVIEW

    db.commit()
    db.refresh(ticket)

    log_audit_event(
        db=db,
        action="TICKET_ASSIGNED",
        user=current_user,
        target_ticket_id=ticket.id,
        details=f"Ticket #{ticket.ticket_number} assigned to technician {tech.full_name} ({tech.email})",
        request=request
    )

    return ticket

@router.post("/{ticket_id}/attachments", response_model=AttachmentResponse)
async def upload_attachment(
    ticket_id: str,
    file: UploadFile = File(...),
    file_type: str = Form("IMAGE_EVIDENCE"),
    request: Request = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    ticket = db.query(Ticket).filter(Ticket.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found.")
    
    # Check permissions
    if current_user.role == UserRole.USER and ticket.reported_by_id != current_user.id:
        raise HTTPException(status_code=403, detail="Cannot upload photos to another user's ticket.")

    file_ext = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_ext}"
    ticket_folder = settings.UPLOAD_DIR / ticket.id
    ticket_folder.mkdir(parents=True, exist_ok=True)
    destination = ticket_folder / unique_filename

    content = await file.read()
    async with aiofiles.open(destination, "wb") as f:
        await f.write(content)

    relative_url = f"/uploads/{ticket.id}/{unique_filename}"
    attachment = Attachment(
        ticket_id=ticket.id,
        file_path=relative_url,
        file_name=file.filename or unique_filename,
        file_type=file_type.upper(),
        file_size_bytes=len(content)
    )
    db.add(attachment)
    db.commit()
    db.refresh(attachment)

    log_audit_event(
        db=db,
        action="ATTACHMENT_UPLOADED",
        user=current_user,
        target_ticket_id=ticket.id,
        details=f"Uploaded {file.filename} ({len(content)} bytes) to Ticket #{ticket.ticket_number}",
        request=request
    )

    return attachment

