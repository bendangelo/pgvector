# Define the PostgreSQL version
ARG PG_MAJOR=17
FROM postgres:$PG_MAJOR

# Set PG_MAJOR argument
ARG PG_MAJOR

# Copy the source files (if needed, for pgvector)
COPY . /tmp/pgvector

# Install dependencies for pgvector only
RUN apt-get update && \
    apt-mark hold locales && \
    apt-get install -y --no-install-recommends \
    build-essential \
    postgresql-server-dev-$PG_MAJOR && \
    # Install pgvector
    cd /tmp/pgvector && \
    make clean && \
    make OPTFLAGS="" && \
    make install && \
    mkdir /usr/share/doc/pgvector && \
    cp LICENSE README.md /usr/share/doc/pgvector && \
    rm -r /tmp/pgvector && \
    # Clean up dependencies
    apt-get remove -y \
    build-essential \
    postgresql-server-dev-$PG_MAJOR && \
    apt-get autoremove -y && \
    apt-mark unhold locales && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      apt-transport-https \
      bzip2 \
      ca-certificates \
      curl \
      gcc \
      libc6-dev \
      make \
  &&  if grep -q "deb-src" /etc/apt/sources.list.d/pgdg.list > /dev/null; then \
        echo "deb [trusted=yes] https://apt.fury.io/abcfy2/ /" >/etc/apt/sources.list.d/fury.list; \
        apt-get update; \
      fi \
  && LIBPQ5_VER="$(dpkg-query --showformat='${Version}' --show libpq5)" \
  && apt-get install -y libpq-dev="${LIBPQ5_VER}" "postgresql-server-dev-${PG_MAJOR}=${PG_VERSION}" \
  && curl -sSkLf "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" | tar xjf - \
  && ZHPARSER_URL="https://github.com/amutu/zhparser/archive/master.tar.gz" \
  &&  if [ x"${USE_CHINA_MIRROR}" = x1 ]; then \
        ZHPARSER_URL="https://mirror.ghproxy.com/${ZHPARSER_URL}"; \
      fi \
  && curl -sSkLf "${ZHPARSER_URL}" | tar xzf - \
  && cd scws-1.2.3 \
  && ./configure \
  && make -j$(nproc) install V=0 \
  && cd /zhparser-master \
  && make -j$(nproc) install \
  && apt-get purge -y gcc \
        make \
        libc6-dev \
        curl \
        bzip2 \
        apt-transport-https \
        ca-certificates \
        libpq-dev="${LIBPQ5_VER}" \
        "postgresql-server-dev-${PG_MAJOR}=${PG_VERSION}" \
  && apt-get autoremove --purge -y \
  && apt-get clean \
  && rm -rf /zhparser-master \
    /scws-1.2.3 \
    /etc/apt/sources.list.d/fury.list \
    /var/lib/apt/lists/*

# Expose the PostgreSQL port
EXPOSE 5432
