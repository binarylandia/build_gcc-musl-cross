ARG DOCKER_BASE_IMAGE
FROM $DOCKER_BASE_IMAGE

SHELL ["bash", "-euxo", "pipefail", "-c"]

RUN set -euxo pipefail >/dev/null \
&& export DEBIAN_FRONTEND=noninteractive \
&& apt-get update -qq --yes \
&& apt-get install -qq --no-install-recommends --yes \
  bash \
  bzip2 \
  ca-certificates \
  curl \
  git \
  make \
  patch \
  sed \
  sudo \
  tar \
  xz-utils \
>/dev/null \
&& rm -rf /var/lib/apt/lists/* \
&& apt-get clean autoclean >/dev/null \
&& apt-get autoremove --yes >/dev/null

# HACK: symlinking `ar` is needed for GCC 9.4.0 - it relies on `ar` command, rather than reading the $AR in cross environment
RUN set -euxo pipefail >/dev/null \
&& curl -fsSL "https://more.musl.cc/10/x86_64-linux-musl/x86_64-linux-musl-cross.tgz" | tar -C "/usr" -xz --strip-components=1 \
&& ln -fs /usr/x86_64-linux-musl/bin/ar /usr/bin/ar \
&& which ar \
&& which x86_64-linux-musl-gcc \
&& /usr/bin/x86_64-linux-musl-gcc -v

ARG USER=user
ARG GROUP=user
ARG UID
ARG GID

ENV USER=$USER
ENV GROUP=$GROUP
ENV UID=$UID
ENV GID=$GID
ENV TERM="xterm-256color"
ENV HOME="/home/${USER}"

COPY docker/files /

RUN set -euxo pipefail >/dev/null \
&& /create-user \
&& sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' \
&& sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' \
&& sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' \
&& echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
&& touch ${HOME}/.hushlogin \
&& chown -R ${UID}:${GID} "${HOME}"


USER ${USER}
