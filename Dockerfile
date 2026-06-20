FROM lcnetdev/scriptshifter-base:latest
ENV WORKROOT="/usr/local/scriptshifter/src"

# Copy core application files.
WORKDIR ${WORKROOT}
COPY VERSION entrypoint.sh sscli uwsgi.ini wsgi.py ./
COPY scriptshifter ./scriptshifter/
COPY test ./test/

#ENV HF_DATASETS_CACHE="/data/hf/datasets"
RUN ./sscli admin init-db

RUN chmod +x ./entrypoint.sh
#RUN chown -R www:www ${WORKROOT} .

EXPOSE 8000

# For debugging WSGI sessions.
#RUN pip install --break-system-packages remote-pdb
#ENV PYTHONBREAKPOINT=remote_pdb.set_trace

ENTRYPOINT ["./entrypoint.sh"]
