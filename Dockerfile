FROM python:3.10-slim-bullseye

RUN apt update
RUN apt install -y build-essential tzdata gfortran libopenblas-dev libboost-all-dev

ENV TZ=America/New_York

# Copy and compile Kakadu codec.
WORKDIR ${_workroot}

ENV _workroot "/usr/local/scriptshifter/src"

WORKDIR ${_workroot}
COPY requirements.txt ./
RUN pip install -r requirements.txt
COPY entrypoint.sh uwsgi.ini wsgi.py ./

COPY ext ./ext/
#RUN pip install ext/arabic_transliterator

COPY scriptshifter ./scriptshifter/
RUN chmod +x ./entrypoint.sh

RUN addgroup --system www
RUN adduser --system www
RUN gpasswd -a www www
RUN chown -R www:www ${_workroot} .

# Remove development packages.
RUN apt remove -y build-essential
RUN apt autoremove -y

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]
