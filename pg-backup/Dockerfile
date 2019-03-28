FROM alpine:latest

ENV PGHOST='localhost'
ENV PGDATABASE='postgres'
ENV PGUSER='postgres'
ENV PGPASSWORD='password'

ENV S3BUCKET='mybucket'

RUN \
 apk update && \
 apk add --no-cache postgresql

COPY backup-postgres-s3.sh .

ENTRYPOINT [ "/bin/sh" ]
CMD [ "./backup-postgres-s3.sh" ]
