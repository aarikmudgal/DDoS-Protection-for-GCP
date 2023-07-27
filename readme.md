# Terraform GCP Kubernetes Deployment

This repository contains a Terraform script to create a Google Cloud Platform (GCP) Artifact Registry repository, build a Docker image, push the image to the repository, create an Autopilot Kubernetes cluster, and deploy a service with the created image.

## Features

- Create an Autopilot Kubernetes cluster
- Deploy a Kubernetes service with default Nginx image
- Expose the service using Kubernetes Ingress
- Create a Cloud Armor security policy

## Requirements

- [Terraform](https://www.terraform.io/downloads.html)
- [GCP account](https://cloud.google.com/) with required permissions
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

### Terraform

To install Terraform, follow these steps:

1. Download the package from the [Terraform downloads page](https://www.terraform.io/downloads.html).

2. Unzip the package. Terraform runs as a single binary named `terraform`.

3. Move the Terraform binary to a directory included in your system's `PATH`.

For example, on Linux or macOS:

```bash
unzip terraform_*_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

On Windows, you can move the binary to a directory included in your PATH, or add the directory containing the binary to your PATH.

### Google Cloud SDK
To install the Google Cloud SDK:

1. Visit the [Google Cloud SDK documentation](https://cloud.google.com/sdk/docs/install).

2. Follow the installation and initialization instructions for your operating system.

### Google Cloud Account and Project Setup

This SDK includes the gcloud command-line tool, which is necessary to authenticate with Google Cloud, set configuration values, and interact with Google Cloud APIs.

Make sure you have a Google Cloud Platform account. If you don't have one, you can create a new account and take advantage of the [$300 free credit](https://cloud.google.com/free) to get started with any GCP product.

Before you begin, you'll need to set up a Google Cloud Platform project:

1. Create a new GCP project via the [GCP Console](https://console.cloud.google.com/).
2. Enable the GCP services used by this project. You can do that by running the following command:

```bash
gcloud services enable container.googleapis.com
```

### Setup Google Cloud SDK

1. Authenticate your GCP account using the following command:

```bash
gcloud auth login
gcloud auth application-default login
```

2. Set your GCP project ID:

```bash
gcloud config set project <PROJECT_ID>
```

## Terraform Variables Configuration

The `terraform.tfvars` file must be populated with appropriate values for the project to work. Here's an example of what the contents might look like:

```hcl
project = "<YOUR PROJECT ID>"
region = "europe-west1"
repository_id = "<YOUR REPOSITORY ID/NAME>"
location = "europe"
format = "DOCKER"
cluster_name = "<YOUR CLUSTER ID/NAME>"
network = "<YOUR NETWORK NAME>"
subnetwork = "<YOUR SUBNETWORK NAME>"
deployment_name = "<YOUR K8s DEPLOYMENT NAME>"
replicas = 1
image_url = "nginx:latest"
container_port = 80
service_name = "<YOUR SERVICE NAME>"
service_port = 80
target_port = 80
service_type = "NodePort"
policy_name = "<YOUR SECURITY POLICY NAME>"
policy_type = "CLOUD_ARMOR"
```

## Usage

To deploy your infrastructure, follow these steps:

1. Initialize your Terraform workspace, which will download the provider plugins:

```bash
terraform init
```

2. Validate your Terraform configuration:

```bash
terraform validate
```

3. View the actions that Terraform will perform:

```bash
terraform plan
```

4. If everything is as expected, apply the Terraform:

```bash
terraform apply
```

After the process is complete, Terraform will have created your GCP Artifact Registry repository, built and pushed your Docker image, created a GCP Autopilot Kubernetes cluster, deployed your service and also create security policy in Cloud Armor.