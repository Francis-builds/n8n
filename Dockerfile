# ------------------------------------------------------------------
# 1) BUILDER STAGE
# ------------------------------------------------------------------
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-alpine AS builder

# Install fonts, Git, SSH, GraphicsMagick, etc.
RUN apk --no-cache add \
    msttcorefonts-installer \
    fontconfig \
    git \
    openssh \
    graphicsmagick \
    tini \
    tzdata \
    ca-certificates \
    libc6-compat \
    jq \
 && update-ms-fonts \
 && fc-cache -f \
 && rm -rf /var/cache/apk/*

# If you actually need a .npmrc (e.g. private packages), uncomment:
# COPY .npmrc /usr/local/etc/npmrc

# Update npm and install full-icu globally
RUN npm install -g npm@9.9.2 full-icu@1.5.0

# (Optional) If you want Yarn/Pnpm:
# RUN corepack enable && corepack prepare --activate

# If you **are building a local/forked n8n**:
# 1. Copy code and install dependencies
# WORKDIR /app
# COPY package.json package-lock.json ./
# RUN npm install
# COPY . .
#
# 2. Build your custom n8n code
# RUN npm run build
#
# The result: /app now contains your compiled n8n code and node_modules.

# ------------------------------------------------------------------
# 2) FINAL STAGE
# ------------------------------------------------------------------
FROM node:${NODE_VERSION}-alpine

# Copy dependencies (binaries, fonts, etc.) from the builder stage
COPY --from=builder /usr /usr
COPY --from=builder /lib /lib
# If you built local code from a fork:
# COPY --from=builder /app /app

# If you're **not** building from local code, install official n8n now:
RUN npm install -g n8n

# If you want to run the local/forked build, skip the line above
# and instead do:
# WORKDIR /app
# CMD ["npm", "run", "start"]  # or "node packages/cli/bin/n8n" or "npx n8n", etc.

ENV NODE_ICU_DATA /usr/local/lib/node_modules/full-icu
WORKDIR /home/node

# Heroku will map traffic to $PORT,
# but by default n8n listens on 5678, which is fine:
EXPOSE 5678
