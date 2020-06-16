FROM redis:alpine
COPY ./sidekiq_worker_check.sh /data/sidekiq_worker_check.sh
RUN /bin/sh -c "chmod u+x /data/sidekiq_worker_check.sh"
CMD ["/bin/sh", "-c", "sh /data/sidekiq_worker_check.sh"]
