from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr

class UserBase(BaseModel):
    email: str
    full_name: str
    department: Optional[str] = "General"

class UserCreate(UserBase):
    password: str
    role: Optional[str] = "USER"

class UserLogin(BaseModel):
    email: Optional[str] = None
    username: Optional[str] = None
    password: str

    def get_identifier(self) -> str:
        return (self.username or self.email or "").strip().lower()

class UserResponse(UserBase):
    id: str
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class UserRoleUpdate(BaseModel):
    role: str
    is_active: Optional[bool] = None

