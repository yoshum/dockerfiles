#!/bin/bash

USER_ID=${LOCAL_UID:-9001}
GROUP_ID=${LOCAL_GID:-9001}
USER_NAME=${LOCAL_USER:-"user"}

useradd -u ${USER_ID} -o ${USER_NAME}
groupmod -g ${GROUP_ID} ${USER_NAME}

echo "${USER_NAME}  ALL=NOPASSWD: ALL" >> /etc/sudoers

export HOME=/home/${USER_NAME}
export PATH=${HOME}/bin:${HOME}/.local/bin:${PATH}

cd /home/${USER_NAME}

exec /usr/sbin/gosu ${USER_NAME} "$@"
