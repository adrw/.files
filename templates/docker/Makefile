# By Andrew Alexander | Source at https://github.com/andrewparadi/docker-cs350-os161
DOCKER_COMPOSE=$(shell which docker-compose)
DOCKER_COMPOSE_TARGETS=-f docker-compose.yml

define DOCKER_NICE
  trap '$(DOCKER_COMPOSE) $(DOCKER_COMPOSE_TARGETS) down' SIGINT SIGTERM && \
  $(DOCKER_COMPOSE) $(DOCKER_COMPOSE_TARGETS)
endef

export DOCKER_NICE

default: pull

init:

build_init: init
	bash -c "if [[ ! -f ./docker-compose.yml ]]; then wget https://raw.githubusercontent.com/adrw/docker-os161/master/docker-compose.yml -O docker-compose.yml; fi"
	bash -c "if [[ ! -f ./Dockerfile ]]; then wget https://raw.githubusercontent.com/adrw/docker-os161/master/Dockerfile -O Dockerfile; fi"

build: build_init
	bash -c "$$DOCKER_NICE build"
	# bash -c "rm *.gz"
	bash -c "docker run -it -v $(shell pwd)/src:/root/cs350-os161 --entrypoint /bin/bash cs350work_os161"

rebuild: build_init
	bash -c "$$DOCKER_NICE build --no-cache"
	bash -c "rm *.gz"
	bash -c "docker run -it -v $(shell pwd)/src:/root/cs350-os161 --entrypoint /bin/bash cs350work_os161"

run: init
	bash -c "docker run -it -v $(shell pwd)/src:/root/cs350-os161 --entrypoint /bin/bash andrewparadi/cs350-os161:latest"

pull: init
	bash -c "docker pull andrewparadi/cs350-os161:latest"
	bash -c "docker run -it -v $(shell pwd)/src:/root/cs350-os161 --entrypoint /bin/bash andrewparadi/cs350-os161:latest"

down:
	bash -c "$$DOCKER_NICE down"

.PHONY: init
.PHONY: build
.PHONY: rebuild
.PHONY: run
