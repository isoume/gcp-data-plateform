#!/bin/bash
set_acces_token() {
  unset access_token
  gcloud auth login
  # Generate GCP Access Token
  ACCESS_TOKEN=$(gcloud auth print-access-token)

  # Export the Token as Environment Variable
  export GOOGLE_OAUTH_ACCESS_TOKEN="$ACCESS_TOKEN"
  return 0
}

set_acces_token