FROM nerodon/icarus-dedicated:latest

USER root

RUN dpkg --add-architecture i386 \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      wine32:i386 \
      winbind \
      xvfb \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

USER steam
