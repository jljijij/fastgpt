# syntax=docker/dockerfile:1

# Build stage
FROM hub.1ms.run/library/node:20 AS builder
WORKDIR /app

# Enable pnpm via corepack
RUN corepack enable

# Copy workspace files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.json ./
COPY packages ./packages
COPY projects ./projects
COPY scripts ./scripts
COPY env.d.ts ./

# Install dependencies and build application
RUN pnpm install --frozen-lockfile
RUN pnpm --filter app build

# Production image
FROM hub.1ms.run/library/node:20-alpine AS runner
WORKDIR /app
RUN corepack enable

# Copy build artifacts
COPY --from=builder /app /app

ENV NODE_ENV=production
EXPOSE 3000

CMD ["pnpm", "--filter", "app", "start"]
