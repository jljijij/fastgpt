# syntax=docker.1ms.run/docker/dockerfile:1

############################
# Build stage
############################
FROM docker.1ms.run/library/node:20 AS builder
WORKDIR /app

# Enable pnpm via corepack & use China registries
RUN corepack enable \
 && npm config set registry https://registry.npmmirror.com \
 && corepack prepare pnpm@latest --activate \
 && pnpm config set registry https://registry.npmmirror.com

# Copy workspace files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.json ./
COPY packages ./packages
COPY projects ./projects
COPY scripts ./scripts
COPY env.d.ts ./

# Install deps & build
RUN pnpm install --frozen-lockfile
RUN pnpm --filter app build

############################
# Production image
############################
FROM docker.1ms.run/library/node:20-alpine AS runner
WORKDIR /app

# Enable pnpm & keep China registry for any runtime installs
RUN corepack enable \
 && npm config set registry https://registry.npmmirror.com \
 && corepack prepare pnpm@latest --activate \
 && pnpm config set registry https://registry.npmmirror.com

# Copy build artifacts
COPY --from=builder /app /app

ENV NODE_ENV=production

CMD ["pnpm", "--filter", "app", "start"]
