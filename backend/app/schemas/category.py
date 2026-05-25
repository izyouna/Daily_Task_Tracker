import uuid
from datetime import datetime
from pydantic import BaseModel, Field

class CategoryBase(BaseModel):
    name: Field(..., max_length=50)
    name: str
    color_hex: str = Field("#7F8C8D", max_length=7, pattern=r"^#(?:[0-9a-fA-F]{3}){1,2}$")

class CategoryCreate(CategoryBase):
    pass

class CategoryUpdate(BaseModel):
    name: str | None = Field(None, max_length=50)
    color_hex: str | None = Field(None, max_length=7, pattern=r"^#(?:[0-9a-fA-F]{3}){1,2}$")

class CategoryResponse(CategoryBase):
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True
