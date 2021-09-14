NAME   := napcs/s3server
TAG    := 0.6.0
IMG    := ${NAME}:${TAG}
LATEST := ${NAME}:latest

image:
	@docker build -t ${IMG} .
	@docker tag ${IMG} ${LATEST}

push:
	@docker push ${IMG}
	@docker push ${LATEST}

