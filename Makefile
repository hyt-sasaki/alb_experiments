AWS_ACCOUNT_ID = 146161350821
AWS_REGION = ap-northeast-1
ECR_REGISTRY = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

IMAGE_NAME = experiment-app
IMAGE_TAG = latest
IMAGE_URL = $(ECR_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

DOCKER_FILE_DIR = backend

.PHONY: build deploy

build:
	docker image build --platform linux/amd64 -t $(IMAGE_URL) $(DOCKER_FILE_DIR)

login:
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REGISTRY)

push: build login
	docker image push $(IMAGE_URL)

verify:
	ecspresso verify

deploy-backend:
	ecspresso deploy

deploy-frontend:
	aws s3 cp frontend/index.html s3://hytssk-experiment-static-hosting-pipeline
	aws s3 cp frontend/error.html s3://hytssk-experiment-static-hosting-pipeline
	aws s3 cp frontend/login.js s3://hytssk-experiment-static-hosting-pipeline
