FROM redis:alpine
RUN apk update && apk upgrade
RUN apk add --no-cache\
  curl
COPY ./sidekiq-worker-check.sh /data/sidekiq-worker-check.sh
RUN /bin/sh -c "chmod u+x /data/sidekiq-worker-check.sh"
CMD ["/bin/sh", "-c", "sh /data/sidekiq-worker-check.sh"]
