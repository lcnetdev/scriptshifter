FROM python:3.13-slim-trixie

ENV LC_ALL=C.UTF-8
ENV TZ="America/New_York"
ENV WORKROOT="/usr/local/scriptshifter/src"

RUN apt update
RUN apt install -y locales tzdata build-essential git
RUN locale-gen
RUN dpkg-reconfigure locales

RUN addgroup --system www
RUN adduser --system www
RUN gpasswd -a www www

ENV HF_DATASETS_CACHE="/data/hf/datasets"

# Copy external dependencies.
WORKDIR ${WORKROOT}
COPY ext ./ext/
COPY requirements.txt ./
ENV CFLAGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
RUN pip install --no-cache-dir --break-system-packages -r requirements.txt

# Remove development packages.
RUN apt remove -y build-essential git
RUN apt autoremove -y
