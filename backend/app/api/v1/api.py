from fastapi import APIRouter
from app.api.v1.endpoints import auth, categories, tags, tasks

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(categories.router, prefix="/categories", tags=["categories"])
api_router.include_router(tags.router, prefix="/tags", tags=["tags"])
api_router.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
