locals {
  local_image_name            = lower(replace(var.app_name, "/[^\\w]+/", ""))

  ecr_image_tag_1             = "latest"
  ecr_image_tag_2             = random_pet.image_tag_petname.id

  ecr_image_url_1             = "${aws_ecr_repository.registry.repository_url}:${local.ecr_image_tag_1}"
  ecr_image_url_2             = "${aws_ecr_repository.registry.repository_url}:${local.ecr_image_tag_2}"

  docker_build_trigger        = {
    dockerfile                = filesha1("${path.module}/src/Dockerfile")
    app_py                    = filesha1("${path.module}/src/main.py")    
  }
  
}

resource "aws_ecr_repository" "registry" {
  name                        = local.local_image_name
  image_tag_mutability        = "MUTABLE"

  image_scanning_configuration {
    scan_on_push              = false
  }

  lifecycle {
    #prevent_destroy           = true
  }

  tags                        = local.common_tags
}

resource "random_pet" "image_tag_petname" {
  keepers = local.docker_build_trigger
}

# Equivalent of aws ecr get-login
data "aws_ecr_authorization_token" "ecr_token" {}

resource "null_resource" "docker_build_deploy" {
  triggers = random_pet.image_tag_petname.keepers

  # docker build 
  provisioner "local-exec" {
    command                   = "docker build -t ${local.local_image_name}:latest -t ${local.ecr_image_url_1} -t ${local.ecr_image_url_2} ./src"
  }

  # docker login 
  provisioner "local-exec" {
    command                   = "echo ${data.aws_ecr_authorization_token.ecr_token.password} | docker login --username ${data.aws_ecr_authorization_token.ecr_token.user_name} --password-stdin ${data.aws_ecr_authorization_token.ecr_token.proxy_endpoint}"
  }

  # docker tag and push
  provisioner "local-exec" {
    command                   = "docker push ${local.ecr_image_url_2}"
  }

  depends_on                  = [ aws_ecr_repository.registry ]
}

/*

To test docker container, run as follows: 

docker image ls
docker run -it --entrypoint /bin/sh [docker_image]

*/