#!/bin/bash -x
sleep 2
if [ ! -d "$PROJECTNAME" ]; then
  django-admin startproject "$PROJECTNAME"
fi
cd "$PROJECTNAME"
echo "$@"
if [ -z "$1" ]; then
  exec python manage.py runserver 0.0.0.0:8000
else
  exec "$@"
fi
