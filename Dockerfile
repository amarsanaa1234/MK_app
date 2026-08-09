FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates xz-utils unzip \
    && rm -rf /var/lib/apt/lists/*

# Локал дээр ашигласантай ижил эх сурвалжаас Flutter SDK татна (хувилбарын зөрчлөөс сэргийлнэ)
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter config --enable-web && flutter precache --web

WORKDIR /app
COPY . .

# Docker дээрх backend container-ийн 8081 порт руу host-оос (browser-ээс) хандана
ARG API_BASE_URL=http://localhost:8081

RUN flutter pub get
RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
