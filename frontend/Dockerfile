# Frontend Dockerfile (Flutter web -> nginx)
# Build with context = frontend/

FROM cirrusci/flutter:stable AS builder
WORKDIR /app

# Copy project files and get dependencies
COPY pubspec.* ./
RUN flutter pub get
COPY . .

# Build web release
RUN flutter build web --release

# Serve with nginx
FROM nginx:stable-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
