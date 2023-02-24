#!/usr/bin/env bash
set -e

if [[ -f "$SERVICE_ACCOUNT_JSON" ]]; then
        gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_JSON >/dev/null
fi

if [[ -f "$BASH_SCRIPT" ]]; then
        . $BASH_SCRIPT
else
        exec "$@"
fi
