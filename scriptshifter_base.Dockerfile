FROM python:3.10-slim-bookworm

RUN apt update
RUN apt install -y build-essential tzdata gfortran libopenblas-dev libboost-all-dev libpcre2-dev

ENV TZ=America/New_York
ARG WORKROOT "/usr/local/scriptshifter/src"

RUN addgroup --system www
RUN adduser --system www
RUN gpasswd -a www www

ENV HF_DATASETS_CACHE /data/hf/datasets

# Copy external dependencies.
WORKDIR ${WORKROOT}
COPY ext ./ext/
COPY deps.txt ./
RUN pip install --no-cache-dir -r deps.txt

# Remove development packages.
RUN apt remove -y build-essential git
RUN apt autoremove -y
