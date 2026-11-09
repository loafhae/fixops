from typing import Optional, List
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.core.security import decode_access_token
from backend.app.models.user import User, UserRole
from backend.app.models.audit_log import AuditLog
from backend.app.models.notification import Notification

security_scheme = HTTPBearer(auto_error=False)

def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme),
    db: Session = Depends(get_db)
) -> User:
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication credentials were not provided."
        )
    
    payload = decode_access_token(credentials.credentials)
    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token."
        )
    
    user_id = payload.get("sub")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account no longer exists."
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated."
        )
    return user

def require_roles(allowed_roles: List[str]):
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Requires one of roles: {allowed_roles}"
            )
        return current_user
    return role_checker

def log_audit_event(
    db: Session,
    action: str,
    user: Optional[User] = None,
    target_ticket_id: Optional[str] = None,
    details: Optional[str] = None,
    request: Optional[Request] = None
):
    ip_address = None
    if request:
        ip_address = request.client.host if request.client else None

    audit_entry = AuditLog(
        user_id=user.id if user else None,
        user_email=user.email if user else "SYSTEM",
        action=action,
        target_ticket_id=target_ticket_id,
        details=details,
        ip_address=ip_address
    )
    db.add(audit_entry)
    db.commit()


def create_notifications(
    db: Session,
    recipients: List[User],
    event_type: str,
    message: str,
    ticket_id: Optional[str] = None,
    exclude_user_id: Optional[str] = None,
):
    recipient_ids = {
        user.id
        for user in recipients
        if user.is_active and user.id != exclude_user_id
    }
    db.add_all(
        Notification(
            recipient_id=recipient_id,
            ticket_id=ticket_id,
            event_type=event_type,
            message=message,
        )
        for recipient_id in recipient_ids
    )
