FROM lcnetdev/scriptshifter-base:latest
ARG WORKROOT "/usr/local/scriptshifter/src"

# Copy core application files.
WORKDIR ${WORKROOT}
COPY entrypoint.sh uwsgi.ini wsgi.py VERSION ./
COPY scriptshifter ./scriptshifter/
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

RUN chmod +x ./entrypoint.sh
#RUN chown -R www:www ${WORKROOT} .

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]
