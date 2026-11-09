from collections import deque

from fastapi import APIRouter, Depends, HTTPException, Query, status

from backend.app.api.deps import require_roles
from backend.app.core.config import settings
from backend.app.models.user import User, UserRole

router = APIRouter(prefix="/system", tags=["System Administration"])


@router.get("/logs", response_model=list[str])
def get_system_logs(
    limit: int = Query(200, ge=1, le=500),
    current_user: User = Depends(require_roles([UserRole.ADMIN])),
):
    log_path = settings.LOG_DIR / "fixops.log"
    try:
        with log_path.open("r", encoding="utf-8") as log_file:
            return list(deque(log_file, maxlen=limit))
    except OSError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="System log file is currently unavailable.",
        ) from error
