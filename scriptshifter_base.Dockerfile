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

# NLTK data used by piraye (Arabic normalizer). The web app runs as the
# unprivileged "www" user, whose home is /nonexistent, so the data must live
# in a system-wide location that www can read. NLTK_DATA is also where
# nltk.download() writes, so it must be owned by www.
#
# piraye looks up the wrong resource path ("impl/punkt" instead of
# "tokenizers/punkt") and, failing that, calls nltk.download() on every import,
# which needs network access. The "impl" symlink satisfies that lookup so the
# app starts offline without hitting the NLTK index.
ENV NLTK_DATA="/usr/local/share/nltk_data"
RUN python -c "import nltk; nltk.download('punkt', download_dir='$NLTK_DATA')" \
    && ln -s tokenizers $NLTK_DATA/impl \
    && chmod -R a+rX $NLTK_DATA \
    && chown -R www:www $NLTK_DATA

# Remove development packages.
RUN apt remove -y build-essential git
RUN apt autoremove -y
