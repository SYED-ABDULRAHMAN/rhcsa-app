# Multi-stage build with Alpine
FROM node:18-alpine as builder

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    pkgconfig \
    libx11-dev \
    libxkbfile-dev \
    libsecret-dev \
    linux-headers

WORKDIR /opt/rhcsa-app

# Copy package files first (for better caching)
COPY package.json ./
COPY package-lock.json ./

# Install dependencies and force rebuild node-pty
RUN npm install && \
    npm rebuild node-pty --build-from-source

# Copy all application directories and files
COPY server.js ./
COPY lib/ ./lib/
COPY questions/ ./questions/
COPY validation/ ./validation/
COPY public/ ./public/

RUN chmod +x validation/*.sh

# Runtime stage
FROM node:18-alpine

# Install runtime dependencies
RUN apk add --no-cache \
    sudo \
    bash \
    shadow \
    util-linux \
    coreutils \
    findutils \
    grep \
    sed \
    gawk \
    libx11 \
    libxkbfile \
    libsecret

WORKDIR /opt/rhcsa-app

COPY --from=builder /opt/rhcsa-app ./

RUN adduser -D -s /bin/bash labuser && \
    echo 'labuser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R labuser:labuser /opt/rhcsa-app

USER labuser

EXPOSE 3000

CMD ["npm", "start"]
