UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
	OS_X   := true
	SHELL  := /bin/bash
else
	OS_DEB := true
	SHELL  := /bin/bash
endif

help: ## °-> show this help  the default action
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'| column -t -s $$'°'

default: help

install: build_devops_docker_image create_container ## °-> setup the whole environment to run this proj 

run: ## °-> run some function , in this case hello world
	docker exec -it proj-devops-con perl ./src/perl/scripts/run.pl

build_devops_docker_image: ## °-> build the devops docker image
	docker build . -t proj-devops-img --no-cache --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) -f src/docker/devops/Dockerfile

build_devops_docker_image_cached: ## °-> build the devops docker image but use the cashe
	docker build . -t proj-devops-img --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) -f src/docker/devops/Dockerfile

create_container: ## °-> create a new container our of the build img
	-docker container stop $$(docker ps -aqf "name=proj-devops-con"); docker container rm $$(docker ps -aqf "name=proj-devops-con")
	docker run -d -v $$(pwd):/opt/min-perl-wrapp \
   	-v $$HOME/.ssh:/home/ubuntu/.ssh \
		--name proj-devops-con proj-devops-img ; 
	echo -e to attach run: "\ndocker exec -it proj-devops-con /bin/bash"
	echo -e to get help run: "\ndocker exec -it proj-devops-con ./deploy --help"

stop_container: ## °-> stop the devops running container
	docker container stop $$(docker ps -aqf "name=proj-devops-con"); docker container rm $$(docker ps -aqf "name=proj-devops-con")

zip_me: ## °-> zip the whole project without the .git dir
	-rm -v ../min-perl-wrapp.zip ; zip -r ../min-perl-wrapp.zip  . -x '*.git*'
	
