ARG UBUNTU_VERSION=18.04
FROM ubuntu:$UBUNTU_VERSION

RUN apt-get -y update &&
  apt-get -y install gosu

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
