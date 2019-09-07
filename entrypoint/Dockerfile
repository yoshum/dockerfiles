ARG UBUNTU_VERSION=18.04
FROM ubuntu:$UBUNTU_VERSION

RUN apt-get -y update \
  && apt-get -y install gosu \
  && find /var/lib/apt/lists \
    /usr/share/man \
    /usr/share/doc \
    /var/log \
    -type f -exec rm -f {} +

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]
