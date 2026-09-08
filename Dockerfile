# syntax=docker/dockerfile:1

# SPDX-FileCopyrightText: 2025 Pagefault Games
# SPDX-FileContributor: domagoj03
#
# SPDX-License-Identifier: AGPL-3.0-only

ARG NODE_VERSION=24.9
ARG OS=alpine

FROM node:${NODE_VERSION}-${OS}

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install git
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Enable and prepare pnpm
RUN corepack enable && corepack prepare pnpm@10.34.5 --activate

# Copy project files
COPY . .

# Install dependencies without running lifecycle scripts
RUN --mount=type=cache,target=/home/appuser/.pnpm-store \
    pnpm install --frozen-lockfile --ignore-scripts && \
    rm -rf /home/appuser/.pnpm-store/*

# Build static production bundle
RUN pnpm build

# Change ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Environment variables
ENV VITE_BYPASS_LOGIN=1 \
    VITE_BYPASS_TUTORIAL=0 \
    NEXT_TELEMETRY_DISABLED=1 \
    PNP_HOME=/home/appuser/.shrc \
    NODE_ENV=production

# Expose Render's default port
EXPOSE 10000

# Serve static build using pnpm dlx serve
CMD ["pnpm", "dlx", "serve", "-s", "dist", "-l", "10000"]
