#!/bin/bash

./configure.sh
docker build -t motbus3/jupyter-lab .
