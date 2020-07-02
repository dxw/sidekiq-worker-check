#!/bin/bash
set -e
set -o pipefail

usage() {
  echo "Usage: $(basename "$0") [OPTIONS]" 1>&2
  echo "  -h               - help"
  echo "  -H               - host ( default localhost )"
  echo "  -p               - port ( default 6379 )"
  echo "  -u               - slack webhook url ( required )"
  echo "  -n               - service name ( required )"
  echo "  -w               - warning time ( default 300 seconds )"
  echo "  -c               - critical time ( default 600 seconds )"
  echo "  -t               - test (outputs to terminal only)"
  exit 1
}

send_slack_message() {
  curl -s -X POST -H "Content-type: application/json" --data "{\"text\":\"$1\"}" "$SLACK_WEBHOOK_URL"
}

# if there are no arguments passed exit with usage
if [ $# -lt 1 ];
then
 usage
fi

HOST=localhost
PORT=6379
WARNING=300
CRITICAL=600
TEST=0

while getopts "H:p:u:n:w:c:th" opt; do
  case $opt in
    H)
      HOST=$OPTARG
      ;;
    p)
      PORT=$OPTARG
      ;;
    u)
      SLACK_WEBHOOK_URL=$OPTARG
      ;;
    n)
      SERVICE_NAME=$OPTARG
      ;;
    w)
      WARNING=$OPTARG
      ;;
    t)
      TEST=1
      ;;
    c)
      CRITICAL=$OPTARG
      ;;
    h)
      usage
      exit;;
    *)
      usage
      exit;;
  esac
done


if [ -z "$SLACK_WEBHOOK_URL" ]; then
  usage
fi
if [ -z "$SERVICE_NAME" ]; then
  usage
fi

last_sidekiq_run=$(redis-cli -h "$HOST" -p "$PORT" MGET sidekiq:last_job_perform_at)

if [ -z "$last_sidekiq_run" ]
then
  echo "Could not get Sidekiq last run information"
  exit 3
fi

now=$(date +%s)
time_since_last_run=$((now - last_sidekiq_run))

ALERT_LEVEL="OKAY"
EXIT_CODE=0

if [ $time_since_last_run -ge "$WARNING" ]
then
  ALERT_LEVEL="WARNING"
  EXIT_CODE=1
fi

if [ $time_since_last_run -ge "$CRITICAL" ]
then
  ALERT_LEVEL="CRITICAL"
  EXIT_CODE=2
fi

MESSAGE="$ALERT_LEVEL: Last sidekiq worker performed $time_since_last_run seconds ago on $SERVICE_NAME"

if [[ "$TEST" -eq 1 || "$EXIT_CODE" -eq 0 ]];
then
  echo "$MESSAGE"
else
  send_slack_message "$MESSAGE"
fi

exit "$EXIT_CODE"
