#!/bin/bash

docker run --gpus all -ti --rm -v ${HOME}:/home/fox/workspace -p 8888:8888 motbus3/jupyter-lab
#docker run --gpus all -ti -v ${HOME}:/home/fox/workspace -p 8888:8888 motbus3/jupyter-lab
