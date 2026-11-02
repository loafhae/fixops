from collections import Counter
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.models.user import User, UserRole
from backend.app.models.ticket import Ticket, TicketStatus, TicketPriority
from backend.app.schemas.ticket import TicketStatsResponse
from backend.app.api.deps import require_roles

router = APIRouter(prefix="/stats", tags=["System Analytics"])

@router.get("/", response_model=TicketStatsResponse)
def get_system_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.ADMIN, UserRole.TECHNICIAN]))
):
    tickets = db.query(Ticket).all()
    total = len(tickets)
    
    open_count = sum(1 for t in tickets if t.status in [TicketStatus.SUBMITTED, TicketStatus.UNDER_REVIEW, TicketStatus.IN_PROGRESS])
    resolved_count = sum(1 for t in tickets if t.status == TicketStatus.RESOLVED)
    critical_count = sum(1 for t in tickets if t.priority == TicketPriority.CRITICAL and t.status != TicketStatus.RESOLVED)
    
    category_counts = Counter(t.category for t in tickets)
    priority_counts = Counter(t.priority for t in tickets)
    status_counts = Counter(t.status for t in tickets)
    
    return TicketStatsResponse(
        total_tickets=total,
        open_tickets=open_count,
        resolved_tickets=resolved_count,
        critical_tickets=critical_count,
        by_category=dict(category_counts),
        by_priority=dict(priority_counts),
        by_status=dict(status_counts)
    )

