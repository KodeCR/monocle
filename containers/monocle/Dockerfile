################################
# Monocle - Base image
################################
# Runtime
FROM ubuntu:24.04
WORKDIR /monocle

USER root
ARG  TARGETARCH
ENV  LC_ALL=C.UTF-8 LANG=C.UTF-8 LANGUAGE=C.UTF-8
SHELL ["/bin/bash", "-c"]
RUN  useradd -ms /bin/bash monocle

# certificates
ENV  REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
COPY certs*/* /usr/local/share/ca-certificates/monocle/
RUN  apt-get update -qy \
  && apt-get install -qy --no-install-recommends ca-certificates gpg wget lsb-release \
  && update-ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# git support
RUN  apt-get update -qy \
  && apt-get install -qy --no-install-recommends git git-lfs openssh-client \
  && rm -rf /var/lib/apt/lists/*
# RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN  mkdir -p -m 0700 ~/.ssh && echo "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl" >> ~/.ssh/known_hosts

# user
USER monocle
ENV  MONOCLE=0.1.0
ENV  TERM="xterm-256color"
CMD  ["/bin/bash"]
