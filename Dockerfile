FROM python:3.12-slim

WORKDIR /app

COPY pyproject.toml README.md ./
COPY src/ src/

RUN pip install --no-cache-dir .

ENV MCP_TRANSPORT=streamable-http
ENV MCP_ISSUER_URL=https://sablier-mcp-215397666394.us-central1.run.app

# Cloud Run sets PORT automatically (default 8080)
EXPOSE 8080

CMD ["sablier-mcp"]
