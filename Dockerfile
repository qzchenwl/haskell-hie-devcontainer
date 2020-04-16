FROM centos:7

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set to false to skip installing zsh and Oh My ZSH!
ARG INSTALL_ZSH="false"

# Location and expected SHA for common setup script - SHA generated on release
ARG COMMON_SCRIPT_SOURCE="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/common-redhat.sh"
ARG COMMON_SCRIPT_SHA="dev-mode"

# Configure apt and install packages
RUN update-ca-trust \
    && yum install -y wget \
    && wget -q -O /tmp/common-setup.sh $COMMON_SCRIPT_SOURCE \
    && if [ "$COMMON_SCRIPT_SHA" != "dev-mode" ]; then echo "$COMMON_SCRIPT_SHA /tmp/common-setup.sh" | sha256sum -c - ; fi \
    && /bin/bash /tmp/common-setup.sh "$INSTALL_ZSH" "$USERNAME" "$USER_UID" "$USER_GID" \
    && rm /tmp/common-setup.sh \
    && echo "export PATH=/usr/local/bin:\$PATH" | tee -a /root/.bashrc >> /home/$USERNAME/.bashrc

# Setup Haskell
COPY --from=qzchenwl/docker-hie:9919e2e /usr/local/bin/hie* /usr/local/bin/
RUN yum groupinstall -y "Development Tools" \
    && yum install -y epel-release zlib-devel postgresql-devel ncurses-devel tree wget

RUN curl -sSL https://downloads.haskell.org/~ghc/8.6.5/ghc-8.6.5-x86_64-centos7-linux.tar.xz \
    | tar -xJf - -C /root/ \
    && cd /root/ghc-8.6.5 \
    && ./configure --prefix=/usr/local \
    && make install \
    && cd / \
    && rm -rf /root/ghc-8.6.5

RUN sudo -H -i -u vscode bash -xc 'cat $HOME/.bashrc; echo $PATH; cabal new-update'

