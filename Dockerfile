FROM lcnetdev/scriptshifter-base:latest
ARG WORKROOT "/usr/local/scriptshifter/src"

# Copy core application files.
WORKDIR ${WORKROOT}
COPY VERSION entrypoint.sh sscli uwsgi.ini wsgi.py ./
COPY scriptshifter ./scriptshifter/
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

RUN chmod +x ./entrypoint.sh
#RUN chown -R www:www ${WORKROOT} .

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]
