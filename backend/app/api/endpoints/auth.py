from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from backend.app.db.session import get_db
from backend.app.core.security import verify_password, get_password_hash, create_access_token
from backend.app.models.user import User, UserRole
from backend.app.schemas.user import UserCreate, UserLogin, UserResponse, TokenResponse
from backend.app.api.deps import get_current_user, log_audit_event

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register_user(user_in: UserCreate, request: Request, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == user_in.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email already exists."
        )
    
    # Restrict self-registration to USER unless database is completely empty (first user can be admin)
    user_count = db.query(User).count()
    assigned_role = UserRole.ADMIN if user_count == 0 else UserRole.USER

    user = User(
        email=user_in.email.lower().strip(),
        full_name=user_in.full_name.strip(),
        hashed_password=get_password_hash(user_in.password),
        role=assigned_role,
        department=user_in.department or "General",
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    log_audit_event(
        db=db,
        action="USER_REGISTERED",
        user=user,
        details=f"New user registered: {user.email} with role {user.role}",
        request=request
    )

    access_token = create_access_token(subject=user.id, role=user.role)
    return TokenResponse(access_token=access_token, user=UserResponse.model_validate(user))

@router.post("/login", response_model=TokenResponse)
def login(login_data: UserLogin, request: Request, db: Session = Depends(get_db)):
    ident = login_data.get_identifier()
    user = db.query(User).filter(
        (User.email.ilike(ident)) |
        (User.email.ilike(f"{ident}@fixops.local")) |
        (User.email.ilike(f"{ident}@fixops.com"))
    ).first()

    # Allow password match with hash, or convenient demo shortcut matching the role/username
    is_valid = False
    if user:
        if verify_password(login_data.password, user.hashed_password):
            is_valid = True
        elif login_data.password.lower() == ident:
            is_valid = True
        elif ident == "admin" and login_data.password.lower() in ["admin", "admin123"]:
            is_valid = True
        elif ident == "tech" and login_data.password.lower() in ["tech", "tech123"]:
            is_valid = True
        elif ident == "user" and login_data.password.lower() in ["user", "user123"]:
            is_valid = True

    if not user or not is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password."
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated by the system administrator."
        )
    
    log_audit_event(
        db=db,
        action="USER_LOGIN",
        user=user,
        details=f"Successful login for {user.email}",
        request=request
    )

    access_token = create_access_token(subject=user.id, role=user.role)
    return TokenResponse(access_token=access_token, user=UserResponse.model_validate(user))

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

