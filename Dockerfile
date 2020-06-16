FROM redis:buster

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
  curl

COPY ./sidekiq-worker-check.sh /usr/bin/sidekiq-worker-check.sh

CMD ["sidekiq-worker-check.sh"]
