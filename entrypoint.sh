#!/bin/sh

export PYTHONPATH=$PYTHONPATH:.
export WEBAPP_PIDFILE="/run/scriptshifter_webapp.pid"
export FLASK_APP="scriptshifter.rest_api"
if [ "${TXL_APP_MODE}" == "development" ]; then
    export FLASK_ENV="development"
else
    export FLASK_ENV="production"
fi

host=${TXL_WEBAPP_HOST:-"0.0.0.0"}
port=${TXL_WEBAPP_PORT:-"8000"}

if [ "${FLASK_ENV}" == "development" ]; then
    exec flask run -h $host -p $port
else
    exec uwsgi --uid www --ini ./uwsgi.ini --http "${host}:${port}" $@
fi
