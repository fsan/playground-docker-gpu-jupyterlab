#!/bin/bash

if [ "local" == "$1" ]; then
	echo -n "User:"
	read username
	echo -n "Password: "
	read -s password
	echo
	docker stop -t0 jupyter
	#set -e
	docker run --gpus all -d --rm -v ${HOME}:/home/fox/workspace -p 8000:8000 --name jupyter motbus3/jupyter-lab
	docker exec -u 0 jupyter bash -c "echo -e \"$password\n$password\" | passwd $username "
	docker logs jupyter
else
	docker run --gpus all -d --rm -v ${HOME}:/home/fox/workspace -p 8000:8000 --name jupyter motbus3/jupyter-lab
fi

#docker run --gpus all -ti    -v ${HOME}:/home/fox/workspace -p 8000:8000 motbus3/jupyter-lab
