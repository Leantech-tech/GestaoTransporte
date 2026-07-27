# Backend Dockerfile (Go API)
# Build with context = backend/

FROM golang:1.26-alpine AS builder
WORKDIR /src

# Copy go.mod and go.sum first to cache deps
COPY go.mod go.sum ./
RUN apk add --no-cache git ca-certificates && go mod download

# Copy the rest of the backend sources
COPY . .

# Build the API binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o /app/api ./cmd/api

# Final runtime image
FROM alpine:3.18
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /app/api /usr/local/bin/api

# Ensure curl is available for health checks
RUN apk add --no-cache curl ca-certificates

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
USER app
ENV PORT=8080
CMD ["/usr/local/bin/api"]
