#!/bin/bash

set -e

ORIG=fox
# set your user at USER, if your user contains like reserved bash words I am so sorry for you. 
USER=fox

cp -R .env-example .env
vim bin/start.sh +%s/${ORIG}/${USER}/g +xa
vim Dockerfile +%s/${ORIG}/${USER}/g +xa
vim .env +%s/${ORIG}/${USER}/g +xa
