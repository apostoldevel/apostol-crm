FROM postgres:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
      postgresql-18-pgtap \
      libtap-parser-sourcehandler-pgtap-perl \
    && rm -rf /var/lib/apt/lists/*
