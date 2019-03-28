FROM python:3.7-alpine

RUN \
 apk update && \
 apk add --no-cache postgresql && \
 python3 -m pip install --upgrade pip --no-cache-dir  && \
 python3 -m pip install s3cmd --no-cache-dir

COPY backup-postgres-s3.sh /opt/backup-postgres-s3.sh

ENTRYPOINT [ "/bin/sh" ]
CMD [ "/opt/backup-postgres-s3.sh" ]
