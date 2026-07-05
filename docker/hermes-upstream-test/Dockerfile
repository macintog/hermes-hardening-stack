FROM docker:29-cli AS docker_cli
FROM python:3.11-slim-bookworm

ARG UV_VERSION=0.11.6

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV UV_LINK_MODE=copy

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      ffmpeg \
      gcc \
      git \
      libffi-dev \
      nodejs \
      npm \
      openssh-client \
      procps \
      python3-dev \
      ripgrep && \
    rm -rf /var/lib/apt/lists/*

COPY --from=docker_cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker_cli /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins

RUN python -m pip install --no-cache-dir "uv==${UV_VERSION}"

WORKDIR /workspace

CMD ["bash"]
