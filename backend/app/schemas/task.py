import uuid
from datetime import datetime
from pydantic import BaseModel, Field
from app.schemas.category import CategoryResponse
from app.schemas.tag import TagResponse

class TaskBase(BaseModel):
    title: str = Field(..., max_length=150)
    description: str | None = None
    status: str = Field("Pending", pattern=r"^(Pending|In Progress|Completed)$")
    due_date: datetime | None = None

class TaskCreate(BaseModel):
    title: str = Field(..., max_length=150)
    description: str | None = None
    category_id: uuid.UUID | None = None
    status: str = Field("Pending", pattern=r"^(Pending|In Progress|Completed)$")
    due_date: datetime | None = None
    tag_ids: list[uuid.UUID] = []

class TaskUpdate(BaseModel):
    title: str | None = Field(None, max_length=150)
    description: str | None = None
    category_id: uuid.UUID | None = None
    status: str | None = Field(None, pattern=r"^(Pending|In Progress|Completed)$")
    due_date: datetime | None = None
    tag_ids: list[uuid.UUID] | None = None

class TaskResponse(TaskBase):
    id: uuid.UUID
    user_id: uuid.UUID
    category_id: uuid.UUID | None
    created_at: datetime
    updated_at: datetime
    category: CategoryResponse | None = None
    tags: list[TagResponse] = []

    class Config:
        from_attributes = True
