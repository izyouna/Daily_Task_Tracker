import logging
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.core.config import settings

logger = logging.getLogger("uvicorn.error")

db_uri = settings.SQLALCHEMY_DATABASE_URI
is_sqlite = False

try:
    # Try connecting to PostgreSQL with a 2-second timeout to avoid long hangs
    engine = create_engine(
        db_uri,
        pool_pre_ping=True,
        connect_args={"connect_timeout": 2} if "postgresql" in db_uri else {}
    )
    with engine.connect() as conn:
        logger.info("Database: Connected to PostgreSQL database successfully.")
except Exception as e:
    logger.warning(f"Database connection failed: {e}. Falling back to SQLite for local development.")
    db_uri = "sqlite:///./daily_task.db"
    engine = create_engine(
        db_uri,
        connect_args={"check_same_thread": False}  # Required for SQLite in multi-threaded FastAPI
    )
    is_sqlite = True

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

class Base(DeclarativeBase):
    pass

# Enable foreign keys for SQLite
if is_sqlite:
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

