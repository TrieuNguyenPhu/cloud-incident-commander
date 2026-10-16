"""P0 exposes health only; protected and webhook routes belong to later phases."""

import os

from cic_contracts.generated.api import Health
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum

app = FastAPI(title="Cloud Incident Commander — P0", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.environ.get("CIC_WEB_ORIGIN", "http://127.0.0.1:3000")],
    allow_methods=["GET"],
    allow_headers=["Content-Type"],
)


@app.get("/healthz", response_model=Health, operation_id="get_health")
def health() -> Health:
    return Health(status="ok", version=app.version)


handler = Mangum(app, lifespan="off")
