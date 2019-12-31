#!/bin/bash

set -e

ORIG_NAME=DEFAULT_USERNAME
ORIG_UID=DEFAULT_UID
ORIG_GID=DEFAULT_GID

# set your user at USER, if your user contains like reserved bash words I am so sorry for you. 
DEST_USER=user #$(whoami)
DEST_UID=1000  #$(id -u)
DEST_GID=1000  #$(id -g)

cp -R .env-example .env
cp -R example.dockerfile Dockerfile
cp -R bin/example.start.sh bin/start.sh
vim bin/start.sh +%s/${ORIG_NAME}/${DEST_USER}/g +xa
vim Dockerfile +%s/${ORIG_NAME}/${DEST_USER}/g +%s/${ORIG_UID}/${DEST_UID}/g +%s/${ORIG_GID}/${DEST_GID}/g +xa
vim .env +%s/${ORIG_NAME}/${DEST_USER}/g +%s/${ORIG_UID}/${DEST_UID}/g +%s/${ORIG_GID}/${DEST_GID}/g +xa
