FROM ubuntu:20.04

ARG USERNAME
ARG USER_UID
ARG USER_GID

# Create the user
RUN if [ "$USER_UID" -ne 0 ]; then \
        mkdir -p /etc/sudoers.d \
        && groupadd --force --gid $USER_GID $USER_NAME \
        && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USER_NAME \
        && echo "$USER_NAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME \
        && chmod 0440 /etc/sudoers.d/$USER_NAME \
        && chown -R $USER_NAME:$USER_NAME /home/$USER_NAME; \
    fi

USER ${USER_NAME:-root}
