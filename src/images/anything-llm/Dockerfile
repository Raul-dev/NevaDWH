# AnythingLLM image — Dockerfile lives with Neva RAG assets.
# Build context must be: src/anythingllm/src  (frontend, server, collector, docker)
#
# From repo root (publicdwh_nodejs):
#   docker compose -f docker-compose-WebAI.yml build anything-llm
#
# Equivalent:
#   docker build -f src/images/anything-llm/Dockerfile \
#     --build-arg VITE_BASE_PATH=/nevaaichat/ \
#     -t anythingllm:local \
#     src/anythingllm/src
#
# Kaniko: use numeric UID/GID (USER 1000:1000, --chown=1000:1000) and re-declare
# ARG after every FROM — named USER anythingllm fails with
# "user anythingllm is not a uid and does not exist".

ARG ARG_UID=1000
ARG ARG_GID=1000

FROM ubuntu:noble-20251013 AS base
ARG ARG_UID=1000
ARG ARG_GID=1000

FROM base AS build-arm64
ARG ARG_UID=1000
ARG ARG_GID=1000
RUN echo "Preparing build of AnythingLLM image for arm64 architecture"
ENV NEXT_TELEMETRY_DISABLED=1
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,DL3013
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        unzip curl gnupg libgfortran5 libgbm1 tzdata netcat-openbsd \
        libasound2t64 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
        libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libx11-6 libx11-xcb1 libxcb1 \
        libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
        libxss1 libxtst6 ca-certificates fonts-liberation libappindicator3-1 libnss3 lsb-release \
        xdg-utils git build-essential ffmpeg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -yq --no-install-recommends nodejs && \
    curl -LO https://github.com/yarnpkg/yarn/releases/download/v1.22.19/yarn_1.22.19_all.deb \
        && dpkg -i yarn_1.22.19_all.deb \
        && rm yarn_1.22.19_all.deb && \
    curl -LsSf https://astral.sh/uv/0.6.10/install.sh | sh && \
        mv /root/.local/bin/uv /usr/local/bin/uv && \
        mv /root/.local/bin/uvx /usr/local/bin/uvx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN (getent passwd "$ARG_UID" && userdel -f "$(getent passwd "$ARG_UID" | cut -d: -f1)") || true && \
    (getent group "$ARG_GID" && groupdel "$(getent group "$ARG_GID" | cut -d: -f1)") || true && \
    groupadd -g "$ARG_GID" anythingllm && \
    useradd -l -u "$ARG_UID" -m -d /app -s /bin/bash -g anythingllm anythingllm && \
    mkdir -p /app/frontend/ /app/server/ /app/collector/ && chown -R "$ARG_UID:$ARG_GID" /app

COPY ./docker/docker-entrypoint.sh /usr/local/bin/
COPY ./docker/docker-healthcheck.sh /usr/local/bin/
COPY --chown=1000:1000 ./docker/.env.example /app/server/.env

RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-healthcheck.sh

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN echo "arm64: optional Chromium — place docker/chromium-linux-arm64.zip in build context if scrape needed"

#############################################

FROM base AS build-amd64
ARG ARG_UID=1000
ARG ARG_GID=1000
RUN echo "Preparing build of AnythingLLM image for amd64 architecture"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,DL3013
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        curl gnupg libgfortran5 libgbm1 tzdata netcat-openbsd \
        libasound2t64 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
        libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libx11-6 libx11-xcb1 libxcb1 \
        libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
        libxss1 libxtst6 ca-certificates fonts-liberation libappindicator3-1 libnss3 lsb-release \
        xdg-utils git build-essential ffmpeg && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -yq --no-install-recommends nodejs && \
    curl -LO https://github.com/yarnpkg/yarn/releases/download/v1.22.19/yarn_1.22.19_all.deb \
        && dpkg -i yarn_1.22.19_all.deb \
        && rm yarn_1.22.19_all.deb && \
    curl -LsSf https://astral.sh/uv/0.6.10/install.sh | sh && \
        mv /root/.local/bin/uv /usr/local/bin/uv && \
        mv /root/.local/bin/uvx /usr/local/bin/uvx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN (getent passwd "$ARG_UID" && userdel -f "$(getent passwd "$ARG_UID" | cut -d: -f1)") || true && \
    (getent group "$ARG_GID" && groupdel "$(getent group "$ARG_GID" | cut -d: -f1)") || true && \
    groupadd -g "$ARG_GID" anythingllm && \
    useradd -l -u "$ARG_UID" -m -d /app -s /bin/bash -g anythingllm anythingllm && \
    mkdir -p /app/frontend/ /app/server/ /app/collector/ && chown -R "$ARG_UID:$ARG_GID" /app

COPY ./docker/docker-entrypoint.sh /usr/local/bin/
COPY ./docker/docker-healthcheck.sh /usr/local/bin/
COPY --chown=1000:1000 ./docker/.env.example /app/server/.env

RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-healthcheck.sh

#############################################

# Kaniko does not set BuildKit automatic ARGs; default so FROM is build-amd64.
ARG TARGETARCH=amd64
FROM build-${TARGETARCH} AS build
ARG ARG_UID=1000
ARG ARG_GID=1000
RUN echo "Running common build flow of AnythingLLM image (uid=${ARG_UID})"
# Do not USER by name here — Kaniko cannot resolve "anythingllm" across stages.

ARG BUILDPLATFORM=linux/amd64
FROM --platform=$BUILDPLATFORM node:18-slim AS frontend-build
ARG VITE_BASE_PATH=/
ENV VITE_BASE_PATH=$VITE_BASE_PATH
# Ограничение heap — иначе Kaniko job часто OOMKilled на yarn/vite
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV YARN_NETWORK_CONCURRENCY=1
WORKDIR /app/frontend
COPY ./frontend/package.json ./
RUN yarn install --ignore-engines --network-timeout 100000 --network-concurrency 1 && yarn cache clean
COPY ./frontend/ ./
RUN yarn build
WORKDIR /app

FROM build AS backend-build
ARG ARG_UID=1000
ARG ARG_GID=1000
USER root
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV YARN_NETWORK_CONCURRENCY=1
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
COPY --chown=1000:1000 ./server /app/server/
WORKDIR /app/server
RUN yarn install --production --ignore-engines --network-timeout 100000 --network-concurrency 1 && yarn cache clean
WORKDIR /app

COPY --chown=1000:1000 ./collector/ ./collector/
WORKDIR /app/collector
# Не качать Chromium в CI (система уже тянет deps в amd64-stage; scrape опционален)
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
RUN yarn install --production --ignore-engines --network-timeout 100000 --network-concurrency 1 && yarn cache clean

WORKDIR /app
RUN chown -R 1000:1000 /app
USER 1000:1000

FROM backend-build AS production-build
WORKDIR /app
USER root
COPY --chown=1000:1000 --from=frontend-build /app/frontend/dist /app/server/public
USER 1000:1000

ENV NODE_ENV=production
ENV ANYTHING_LLM_RUNTIME=docker
ENV DEPLOYMENT_VERSION=1.16.0

HEALTHCHECK --interval=1m --timeout=10s --start-period=1m \
  CMD /bin/bash /usr/local/bin/docker-healthcheck.sh || exit 1

ENTRYPOINT ["/bin/bash", "/usr/local/bin/docker-entrypoint.sh"]
