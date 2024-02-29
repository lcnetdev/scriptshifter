FROM python:3.10-slim-bullseye

RUN apt update
RUN apt install -y build-essential tzdata gfortran libopenblas-dev libboost-all-dev

ENV TZ=America/New_York
ENV _workroot "/usr/local/scriptshifter/src"

RUN addgroup --system www
RUN adduser --system www
RUN gpasswd -a www www

WORKDIR ${_workroot}
COPY entrypoint.sh uwsgi.ini wsgi.py ./
COPY ext ./ext/
COPY scriptshifter ./scriptshifter/

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Remove development packages.
RUN apt remove -y build-essential git
RUN apt autoremove -y

RUN chmod +x ./entrypoint.sh
RUN chown -R www:www ${_workroot} .

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]
