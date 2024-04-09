FROM ghcr.io/prefix-dev/pixi:0.18.0-bookworm-slim

COPY ./backend /opt/backend
COPY ./pixi.lock /opt/backend/pixi.lock
COPY ./pixi.toml /opt/backend/pixi.toml
WORKDIR /opt/backend/
RUN pixi install
CMD pixi run uvicorn resume.asgi:application
