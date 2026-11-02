from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from backend.app.db.session import get_db
from backend.app.models.user import User, UserRole
from backend.app.models.audit_log import AuditLog
from backend.app.schemas.audit_log import AuditLogResponse
from backend.app.api.deps import require_roles

router = APIRouter(prefix="/audit-logs", tags=["Activity Audit Trail"])

@router.get("/", response_model=List[AuditLogResponse])
def get_audit_logs(
    action: Optional[str] = None,
    ticket_id: Optional[str] = None,
    limit: int = Query(50, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.ADMIN]))
):
    query = db.query(AuditLog)
    if action:
        query = query.filter(AuditLog.action == action.upper())
    if ticket_id:
        query = query.filter(AuditLog.target_ticket_id == ticket_id)
    
    return query.order_by(desc(AuditLog.timestamp)).limit(limit).all()

