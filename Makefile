.PHONY: unit-tests
unit-tests:
	cd src; go test -v .; cd -;

.PHONY: lint
lint:
	cd src; golangci-lint run -v; cd -;

.PHONY: ssh-pair
ssh-pair:
	ssh-keygen -t ed25519 -C '' -N '' -f ./agent-ssh-key; \
		mv ./agent-ssh-key ./.pipeline/local/jenkins-controller; \
		mv ./agent-ssh-key.pub ./.pipeline/local/jenkins-agent

.PHONY: images
images:
	podman build -t jenkins-controller:0.0 -f ./.pipeline/local/jenkins-controller/Containerfile . && \
		podman build -t jenkins-agent:0.0 -f ./.pipeline/local/jenkins-agent/Containerfile .

.PHONY: net
net:
	podman network create ci --subnet 10.89.0.0/29

.PHONY: install
install:
	make ssh-pair && make images && make net

.PHONY: build-trigger
build-trigger:
	chmod ug+x ./.pipeline/local/jenkins-agent/post-commit; cp ./.pipeline/local/jenkins-agent/post-commit ./.git/hooks/post-commit;

.PHONY: start
start:
	podman run --name jenkins-controller \
		-d -p 8080:8080 \
		--network ci --ip 10.89.0.2 \
		-v ./:/var/jenkins_home/repo \
		localhost/jenkins-controller:0.0 && \
	podman run --name jenkins-agent \
		-d -p 2222:2222 \
		--network ci --ip 10.89.0.3 \
		-v ./:/home/jenkins/agent/repo \
		--privileged \
		localhost/jenkins-agent:0.0

.PHONY: rm
rm:
	podman network rm --force ci && \
		podman image rm localhost/jenkins-controller:0.0 localhost/jenkins-agent:0.0 && \
		rm ./.pipeline/local/jenkins-controller/agent-ssh-key ./.pipeline/local/jenkins-agent/agent-ssh-key.pub
