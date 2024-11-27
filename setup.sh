#!/bin/bash
set_acces_token() {
  unset ACCESS_TOKEN
  # Generate GCP Access Token
  ACCESS_TOKEN=$(gcloud auth print-access-token --impersonate-service-account="iac-provisionning-resources@doctolib-data-dev.iam.gserviceaccount.com")
  # Export the Token as Environment Variable
  export GOOGLE_OAUTH_ACCESS_TOKEN="$ACCESS_TOKEN"
  return 0
}

terraform_init() {
  echo "Initialize the environment"
    terraform init
  return 0
}

terraform_validate() {
  echo "Validate the Code"
    terraform validate
  return 0
}

terraform_plan() {
  set_acces_token
  unset env
  env=$1
  echo "Plan of ${env}"
  terraform plan -input=false -var-file="envs/${env}.tfvars" -var="tf_access_token=${ACCESS_TOKEN}"
  return 0
}

terraform_apply() {
  set_acces_token
  unset env
  env=$1
  echo "Apply of ${env}"
  terraform apply -input=false -var-file="envs/${env}.tfvars" -var="tf_access_token=${ACCESS_TOKEN}"
  return 0
}

terraform_destroy() {
  set_acces_token
  unset env
  env=$1
  echo "Destroy of ${env}"
  terraform destroy -input=false -var-file="envs/${env}.tfvars" -var="tf_access_token=${ACCESS_TOKEN}"
  return 0
}
