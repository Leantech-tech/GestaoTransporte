# Frontend Dockerfile (Flutter web -> nginx)
# Build with context = frontend/

FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app

# Build-time environment for the API URL
ARG API_BASE_URL=http://localhost:8080/api
ENV API_BASE_URL=$API_BASE_URL

# Copy project files and get dependencies
COPY pubspec.* ./
RUN flutter pub get
COPY . .

# Build web release passing the API URL
RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

# Serve with nginx
FROM nginx:stable-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 80
CMD ["/entrypoint.sh"]
