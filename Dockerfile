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

# Expose the PostgreSQL port
EXPOSE 5432
