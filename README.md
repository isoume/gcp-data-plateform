# GCP Infrastructure Setup with Terraform

This repository contains the Terraform configurations to set up and manage the following infrastructure in Google Cloud Platform (GCP):

- **Virtual Private Cloud (VPC)** with public and private subnets across multiple regions.
- **Compute Engine Instances (VMs)** in private subnets for data processing tasks.
- **Cloud SQL** (MySQL) instance for database storage in private subnets.
- **Cloud Storage Buckets** for data storage and backup.
- **IAM Roles and Policies** for secure access to AWS resources.
- **Firewall Rules** for controlling traffic to and from resources.

## Table of Contents
1. [Environment Setup](setup.sh)
2. [Terraform Configuration](main.tf)
3. [Terraform Commands] command
- Initialize the Script<br>
`source ./setup.sh`
- Initialize the environment<br>
`terraform_init`
- Validate the code<br>
`terraform_validate`
- Plan to visualize the resources that will be created after seted a token<br>
`terraform_plan dev` 
- Apply to create resources that you want to provisionned<br>
`terraform_apply dev`


---

## 1. Environment Setup

Before you begin, set up the following:

### 1.1. **Create a Google Cloud Project**
- Log in to the [Google Cloud Console](https://console.cloud.google.com/).
- Create a new project specifically for this infrastructure setup.
- Note the **Project ID** for later use.

### 1.2. **Install Terraform**
- Install Terraform on your local machine. Follow the official [installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli) for your platform.

### 1.3. **Install Google Cloud SDK**
- Install the Google Cloud SDK (`gcloud`) to interact with your Google Cloud account via the command line.
- Follow the installation instructions in the [Google Cloud SDK documentation](https://cloud.google.com/sdk/docs/install).


lauch ./setup.sh to log and set then token provided by google
