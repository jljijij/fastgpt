# syntax=docker.1ms.run/docker/dockerfile:1

############################
# Build stage
############################
FROM docker.1ms.run/library/node:20 AS builder
WORKDIR /app


COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.json ./
COPY packages ./packages
COPY projects ./projects
COPY scripts ./scripts
COPY env.d.ts ./

# 统一国内源 + 禁用 corepack + 预装固定 pnpm（避免联网下载 pnpm tgz）
ENV npm_config_registry=https://registry.npmmirror.com
# node-gyp / Electron / Puppeteer 等二进制加速镜像（按需）
ENV NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
ENV ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
ENV PUPPETEER_DOWNLOAD_HOST=https://npmmirror.com/mirrors
# 如用 node-sass 可启用：
# ENV SASS_BINARY_SITE=https://npmmirror.com/mirrors/node-sass

RUN corepack disable && npm i -g pnpm@9.15.9

# Copy workspace files
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.json ./
COPY packages ./packages
COPY projects ./projects
COPY scripts ./scripts
COPY env.d.ts ./

# Install deps & build
ENV MONGOMS_DISABLE_POSTINSTALL=1
RUN pnpm config set registry https://registry.npmmirror.com \
 && pnpm install --frozen-lockfile \
 && pnpm --filter app build

RUN mkdir -p projects/app/.next/proto && \
    cp -r node_modules/.pnpm/@zilliz+milvus2-sdk-node@*/node_modules/@zilliz/milvus2-sdk-node/dist/proto/proto projects/app/.next/proto/
############################
# Production image
############################
FROM docker.1ms.run/library/node:20-alpine AS runner
WORKDIR /app

# 运行期同样禁用 corepack并预装 pnpm，避免任何运行时下载
ENV npm_config_registry=https://registry.npmmirror.com
RUN corepack disable && npm i -g pnpm@9.15.9 \
 && pnpm config set registry https://registry.npmmirror.com

# Copy build artifacts
COPY --from=builder /app /app

ENV NODE_ENV=production
CMD ["pnpm", "--filter", "app", "start"]
