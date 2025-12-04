FROM python:3.12-slim-bookworm as build

# Performance Optimizations
ENV PYTHONBUFFERED=1 UV_LINK_MODE=copy UV_COMPILE_BYTECODE=1

# Get Packages to be able to install uv
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && apt-get upgrade -y openssl

# Install uv
ADD https://astral.sh/uv/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh

# Set path for uv
ENV PATH="/root/.local/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy pyproject.toml and uv.lock to install dependencies. Cache dependencies separately.
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-install-project --no-dev

# Copy the rest of the application code. UV sync the project.
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv uv sync --frozen --no-dev

# Create non-root user
RUN groupadd -r appuser && useradd --no-log-init -r -g appuser appuser && \
    chown -R appuser:appuser /app /root/.cache/uv

# Runtime stage
FROM python:3.12-slim-bookworm as runtime
WORKDIR /app
COPY --from=build /app /app
ENV PATH="/root/.local/bin:$PATH"

RUN chown -R appuser:appuser /app
USER appuser

# Make sure to expose for OpenTelemetry gRPC port
EXPOSE 4137

CMD ["uv", "run", "--", "python", "main.py"]