FROM public.ecr.aws/lambda/python:3.8

LABEL version="1.0"
LABEL description="Dockerfile to build a container for launching Terraform"
LABEL maintainer="Sachin Hamirwasia <ssacha@amazon.com>"

ARG TERRAFORM_VERSION=0.14.11
ARG FUNCTION_DIR="/var/task"

WORKDIR ${FUNCTION_DIR}

COPY . ${FUNCTION_DIR}

RUN yum -y update && yum -y install unzip && \
  mkdir -p ${FUNCTION_DIR}/bin && cd ${FUNCTION_DIR}/bin && \
  curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  chmod +x ${FUNCTION_DIR}/bin/terraform && \
  pip install --target ${FUNCTION_DIR} awslambdaric && \
  ${FUNCTION_DIR}/bin/terraform -chdir=${FUNCTION_DIR}/terraform init -input=false -backend=false

#FROM public.ecr.aws/lambda/python:3.8 
#WORKDIR ${FUNCTION_DIR}
#ARG FUNCTION_DIR
#COPY --from=0 ${FUNCTION_DIR} ${FUNCTION_DIR}
#ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]

CMD [ "main.lambda_handler" ]
