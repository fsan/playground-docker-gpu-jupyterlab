#!/bin/bash

set -e

ORIG_NAME=DEFAULT_USERNAME
ORIG_UID=DEFAULT_UID
ORIG_GID=DEFAULT_GID
# set your user at USER, if your user contains like reserved bash words I am so sorry for you. 
#USER=DEFAULT_USERNAME
#UID=$(id -u)
GID=$(id -g)

cp -R .env-example .env
cp -R example.dockerfile Dockerfile
vim bin/start.sh +%s/${ORIG_NAME}/${USER}/g +xa
vim Dockerfile +%s/${ORIG_NAME}/${USER}/g +%s/${ORIG_UID}/${UID}/g +%s/${ORIG_GID}/${GID}/g +xa
vim .env +%s/${ORIG_NAME}/${USER}/g +%s/${ORIG_UID}/${UID}/g +%s/${ORIG_GID}/${GID}/g +xa
