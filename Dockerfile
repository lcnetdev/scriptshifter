FROM lcnetdev/scriptshifter-base:latest
ENV WORKROOT="/usr/local/scriptshifter/src"

# Copy core application files.
WORKDIR ${WORKROOT}
COPY VERSION entrypoint.sh sscli uwsgi.ini wsgi.py ./
COPY scriptshifter ./scriptshifter/

# The seq2seq model files (tokenizers, weights, training data) are stored in
# Git LFS. Building from a checkout without LFS content ships 130-byte pointer
# files and the Arabic/Persian S2R engine fails at runtime with an opaque 500.
# Fail the build loudly instead.
RUN if grep -rlq "git-lfs.github.com/spec" scriptshifter/hooks/seq2seq/data; then \
        echo "ERROR: Git LFS files are not checked out." >&2; \
        echo "Install git-lfs and run 'git lfs pull' before building." >&2; \
        exit 1; \
    fi
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
