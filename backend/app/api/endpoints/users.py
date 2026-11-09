from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.models.user import User, UserRole
from backend.app.schemas.user import UserResponse, UserRoleUpdate
from backend.app.api.deps import require_roles, log_audit_event

router = APIRouter(prefix="/users", tags=["User & Access Management"])

@router.get("/", response_model=List[UserResponse])
def list_users(
    role_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.ADMIN]))
):
    query = db.query(User)
    if role_filter:
        query = query.filter(User.role == role_filter.upper())
    return query.order_by(User.created_at.desc()).all()

@router.patch("/{user_id}", response_model=UserResponse)
def update_user_role_or_status(
    user_id: str,
    update_data: UserRoleUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.ADMIN]))
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    
    # Avoid demoting the last active admin
    if user.id == current_user.id and update_data.role != UserRole.ADMIN:
        raise HTTPException(status_code=400, detail="Cannot demote yourself from Admin.")
    
    prev_role = user.role
    user.role = update_data.role.upper()
    if update_data.is_active is not None:
        user.is_active = update_data.is_active
    
    db.commit()
    db.refresh(user)

    log_audit_event(
        db=db,
        action="USER_ROLE_UPDATED",
        user=current_user,
        details=f"Admin {current_user.email} updated role of {user.email} to {user.role} (active={user.is_active})",
        request=request
    )

    return user
