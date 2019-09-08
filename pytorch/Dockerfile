ARG UBUNTU_VERSION=18.04
ARG CUDA_VERSION=10.0

# FROM buildpack-deps:$UBUNTU_VERSION as builder
FROM nvidia/cuda:${CUDA_VERSION}-cudnn7-devel-ubuntu${UBUNTU_VERSION} as builder

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

ENV DEBIAN_FRONTEND=noninteractive
# extra dependencies (over what buildpack-deps already includes)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    libffi-dev \
    libgdbm-dev \
    liblzma-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    uuid-dev \
    zlib1g-dev \
  && find /var/lib/apt/lists \
    /usr/share/man \
    /usr/share/doc \
    /var/log \
    -type f -exec rm -f {} +

ENV GPG_KEY 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
ARG PYTHON_VERSION=3.6.9

RUN set -ex \
  \
  && apt-get update -y \
  && apt-get install -y wget \
  && wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
  && wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
  && gpg --batch --verify python.tar.xz.asc python.tar.xz \
  && { command -v gpgconf > /dev/null && gpgconf --kill all || :; } \
  && rm -rf "$GNUPGHOME" python.tar.xz.asc \
  && mkdir -p /usr/src/python \
  && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
  && rm python.tar.xz \
  \
  && cd /usr/src/python \
  && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
  && ./configure \
    --build="$gnuArch" \
    --enable-loadable-sqlite-extensions \
    --enable-optimizations \
    --enable-shared \
    --with-lto \
    --with-system-expat \
    --with-system-ffi \
    --without-ensurepip \
  && make -j "$(nproc)" \
  # setting PROFILE_TASK makes "--enable-optimizations" reasonable: https://bugs.python.org/issue36044 / https://github.com/docker-library/python/issues/160#issuecomment-509426916
    PROFILE_TASK='-m test.regrtest --pgo \
      test_array \
      test_base64 \
      test_binascii \
      test_binhex \
      test_binop \
      test_bytes \
      test_c_locale_coercion \
      test_class \
      test_cmath \
      test_codecs \
      test_compile \
      test_complex \
      test_csv \
      test_decimal \
      test_dict \
      test_float \
      test_fstring \
      test_hashlib \
      test_io \
      test_iter \
      test_json \
      test_long \
      test_math \
      test_memoryview \
      test_pickle \
      test_re \
      test_set \
      test_slice \
      test_struct \
      test_threading \
      test_time \
      test_traceback \
      test_unicode \
      ' \
  && make install \
  && ldconfig \
  \
  && find /usr/local -type f -name "*.so" -exec strip --strip-unneeded {} + \
  && find /usr/local -depth \
    \( \
      \( -type d -a \( -name test -o -name tests \) \) \
      -o \
      \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    \) -exec rm -rf '{}' + \
  && rm -rf /usr/src/python \
  && find /var/lib/apt/lists \
    /usr/share/man \
    /usr/share/doc \
    /var/log \
    -type f -exec rm -f {} + \
  \
  && python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
  && ln -s idle3 idle \
  && ln -s pydoc3 pydoc \
  && ln -s python3 python \
  && ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 19.2.3
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/309a56c5fd94bd1134053a541cb4657a4e47e09d/get-pip.py
ENV PYTHON_GET_PIP_SHA256 57e3643ff19f018f8a00dfaa6b7e4620e3c1a7a2171fd218425366ec006b3bfe

RUN set -ex; \
  \
  wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
  echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
  apt-get remove wget --purge -y -qq ; \
  \
  python get-pip.py \
  --disable-pip-version-check \
  --no-cache-dir \
  "pip==$PYTHON_PIP_VERSION" \
  ; \
  pip --version; \
  \
  find /usr/local -depth \
    \( \
      \( -type d -a \( -name test -o -name tests \) \) \
      -o \
      \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    \) -exec rm -rf '{}' +; \
  rm -f get-pip.py

ARG PIP_PACKAGES="scikit-learn scipy numpy"
ARG TORCH_PACKAGES="torch torchvision"

RUN pip install --no-cache-dir ${PIP_PACKAGES} \
  && pip install --no-cache-dir ${TORCH_PACKAGES} \
  && find /usr/local -depth \
    \( \
      \( -type d -a \( -name test -o -name tests \) \) \
      -o \
      \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    \) -exec rm -rf '{}' +

RUN rm -rf /usr/local/cuda-${CUDA_VERSION} /usr/local/cuda

#############################################################################
FROM nvidia/cuda:${CUDA_VERSION}-cudnn7-devel-ubuntu${UBUNTU_VERSION}

ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

ENV DEBIAN_FRONTEND=noninteractive

RUN set -ex \
    && apt update \
    && apt-mark unhold \
      apt \
      libcap2 \
      libsemanage1 \
      passwd \
    && apt-get install -y --no-install-recommends \
      libbz2-1.0 \
      libexpat1 \
      libsqlite3-0 \
      zlib1g \
    && (find /usr -type f -name "*.so" -exec strip --strip-unneeded {} + || true)\
    && find /var/lib/apt/lists \
            /usr/share/man \
            /usr/share/doc \
            /var/log \
            -type f -exec rm -f {} +

COPY --from=builder /usr/local /usr/local
RUN /sbin/ldconfig

COPY ./resources/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["python"]