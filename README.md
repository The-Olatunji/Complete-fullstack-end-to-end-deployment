## Complete end to end deployment of a Climate change monitor app on EKS using Terraform 

Climate Change Monitor Tracker 

### Overview 

This climate monitor app was developed with Python to measure air pollution in the atmosphere per time.
The project goal is to package the application as a docker and deploy the app on to a kubernetes cluster using Terraform as a crucial IaC tool for streamline creation and deployment of resources upon the cloud whilst ensuring scalability, reliability, security and best practices.

This project uses Terraform to set up an Amazon EKS (Elastic Kubernetes Service) cluster with a VPC, managed node groups, and IRSA (IAM Roles for Service Accounts) for the Amazon EBS CSI (Container Storage Interface) driver.

## Proposed Deployment Architecture

![Deployment Architecture](<./images/real 3 tier architeture pic.png>)

### Why deploy with Terraform?
While you could use the built-in AWS provisioning processes (UI, CLI, CloudFormation) for EKS clusters, Terraform provides you with several benefits:

* Unified Workflow - If you already use Terraform to deploy AWS infrastructure, you can use the same workflow to deploy both EKS clusters and applications into those clusters.

* Full Lifecycle Management - Terraform creates, updates, and deletes tracked resources without requiring you to inspect an API to identify those resources.

* Graph of Relationships - Terraform determines and observes dependencies between resources. For example, if an AWS Kubernetes cluster needs a specific VPC and subnet configurations, Terraform will not attempt to create the cluster if it fails to provision the VPC and subnet first.


### Why deploy with Terraform?
While you could use the built-in AWS provisioning processes (UI, CLI, CloudFormation) for EKS clusters, Terraform provides you with several benefits:

* Unified Workflow - If you already use Terraform to deploy AWS infrastructure, you can use the same workflow to deploy both EKS clusters and applications into those clusters.

* Full Lifecycle Management - Terraform creates, updates, and deletes tracked resources without requiring you to inspect an API to identify those resources.

* Graph of Relationships - Terraform determines and observes dependencies between resources. For example, if an AWS Kubernetes cluster needs a specific VPC and subnet configurations, Terraform will not attempt to create the cluster if it fails to provision the VPC and subnet first.


### Pre-requisites
* [Terraform](https://www.terraform.io/downloads.html)
* [AWS Account](https://aws.amazon.com/)
* [awscli](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
* [kubectl v1.24.0 or newer](https://kubernetes.io/docs/tasks/tools/)

### Terraform Configuration
This Terraform configuration includes several modules and providers to deploy the EKS cluster and its associated resources.

### 1. AWS Provider
The AWS provider is configured to use the specified AWS region:
```
provider "aws" {
  region = var.region
}
```
### 2. VPC Module
A VPC is created using the [terraform-aws-vpc module](https://github.com/terraform-aws-modules/terraform-aws-vpc). This VPC will host the EKS cluster. The VPC module sets up the networking layer for the EKS cluster. This includes public and private subnets, NAT gateways, and routing tables.


* VPC CIDR: The CIDR block defines the IP address range for the VPC.
* Subnets: The configuration includes both public and private subnets across multiple availability zones (AZs).
    * Public subnets are used for resources that need internet access, like Load Balancers.
    * Private subnets host the Kubernetes nodes, which do not need direct internet exposure.
* NAT Gateway: A NAT Gateway allows instances in the private subnets to access the internet without exposing them to inbound internet traffic.
* Tags: The subnets are tagged for Kubernetes to automatically recognize and use them appropriately.


### 3. EKS Module
The EKS cluster is created using the [terraform-aws-eks module](https://github.com/terraform-aws-modules/terraform-aws-eks).
* Cluster Name and Version: The EKS cluster is identified by the 'cluster_name' and runs the specified Kubernetes version.
* Cluster Endpoint: Public access to the cluster endpoint is enabled, allowing management from outside the VPC.
* Managed Node Groups: Two managed node groups are defined, each with its own set of instance types and scaling configurations.
* Add-ons: The EKS add-on for the Amazon EBS CSI driver is enabled, allowing Kubernetes to manage Amazon EBS volumes.


### 4. IAM Module for IRSA (IAM Roles for Service Accounts)
The IRSA module configures the IAM roles necessary for the EBS CSI driver.
The IAM Roles for Service Accounts (IRSA) module creates IAM roles that allow Kubernetes service accounts to assume specific AWS IAM roles. This is crucial for the Amazon EBS CSI driver, which requires permissions to manage EBS volumes.

### 5. Kubernetes Provider
The Kubernetes provider interacts with the EKS cluster once it is created. It uses the AWS IAM credentials to authenticate and manage Kubernetes resources.

### 6. S3 Backend
This configuration stores the 'terraform statefile' remotely

### Deployment
 To deploy infrastructure run `Terraform init` to initialize the Terraform environment by downloading the necessary provider plugins and modules. `Terraform plan` to generate and review an execution plan to see what actions Terraform will take. `Terraform apply` to deploy the infrastructure as defined in the configuration files.
![k8s cluster](<./images/Screenshot 2025-01-17 230109.png>)
To access the kuberntes cluster using kubectl: 
 
```
aws eks update-kubeconfig --name climate-eks --region us-east-1
```

---

### Kubernetes manifests
1. Namespace:
The k8s namespace yaml file is used to isolate resources within the kubernetes cluster. This ensures that the resources for the Climate Monitor app are scoped under their environment.


2. Deployment
The Deployment defines the application's pod specifications and ensures that the desired number of replicas are running.
**Replicas:3** - ensures high availablity by running three pods of the docker container.

3. Horizontal Pod Autoscaler
The HPA ensures that the app scales based on CPU or memory usage, maintaining efficiency under varying loads.

4. The Service exposes the deployment within the cluster. It uses a ClusterIP for internal communication.

To deploy the application, 
```
kubectl apply -f ./kubernetes/manifests
```
### Kubernetes Ingress
### 1. Ingress Controller
For Ingress to be available for use, an ingress controller in needed to implement the ingress resource which will be created. Popular choice include Traefix, nginx. *In this case my most preferred choice is NGINX ingress controller*.
Run ` kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml ` to deploy the NGINX controller manifest.

Ingress resource specifies the rules for routing traffic and uses the TLS certificate for secure connections.
* Ensure that you have a domain registered and configured to point to your Kubernetes cluster's IP address( The ELB loadbalancer address of the LB that has been generated by ingress controller deployment).

### 2. Ingress and Certificate validation for Secure Connection 
TLS certificate and private key is needed for our domain. we'd generate a self-signed certificate or obtain one from a Certificate Authority like Let's Encrypt.

1. Install and configure cert-manager in your Kubernetes cluster. Cert-manager is a Kubernetes add-on that automates the management and issuance of TLS certificates.

``` 
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.10.0/cert-manager.yaml 
```
2. Declaratively define a cluster Issuer which uses Let's Encrypt to verify that you control the domain 
```
kubectl apply -f ./kubernete/ingress/issuer.yaml
```

3. Next up, create a Certificate resource in Kubernetes, specifying the domain and subdomain name and the ingress resource that will be using the certificate. Cert-Manager stores the issued certificate in the Kubernetes Secret specified in the Certificate resource
``` 
kubectl apply -f ./kubernetes/ingress/certificate.yaml
```

4. Configure your Ingress resource to use the certificate. Add the `cert-manager.io/cluster-issuer` annotation to your Ingress resource, specifying the name of the ClusterIssuer or Issuer resource that was previously created.
``` 
kubectl apply -f ./kubernetes/ingress/issuer.yaml
```


5. Ingress class: 
In order for the ingress resource to correctly route to our designated domain, we define an `IngressClass` and referenced it in the Ingress resource.
``` 
kubectl apply -f ./kubernetes/ingress/ingress-class.yaml
```

6. Apply the changes to your Kubernetes cluster, and cert-manager will automatically request and manage the certificate for your domain.
Run ` kubectl apply -f ./kubernetes/ingress/ingress.yaml `

![Secure Climate monitor app](<./images/Screenshot 2025-01-18 180520.png>)

### CI/CD With Github Actions
This repository also contains a CI/CD pipeline powered by GitHub Actions. The pipeline is designed to automate the provisioning and management of AWS infrastructure, as well as the deployment and management of Kubernetes resources using Amazon EKS .

The CI/CD pipeline is defined in the deploy.yml file under the .github/workflows directory. The workflow includes the following steps:

1. Install Kubectl
  ![kubectl job](<./images/Screenshot 2024-08-21 023114.png>)

1. Set Up AWS Credentials: Configures AWS credentials using GitHub Secrets.

1. Install Terraform: Installs the specified version of Terraform.

1. Terraform Init: Initializes Terraform and sets up the backend configuration.
   
1. Terraform Plan: Generates an execution plan for the Terraform configuration.

1. Terraform Apply: Applies the Terraform plan to create or update infrastructure.

1. Configure kubectl: Sets up kubectl to interact with the EKS cluster using the provided Kubeconfig.

1. Deploy Application

### Environment Variables
The following environment variables are required:
AWS_REGION: AWS region
AWS_ACCESS_KEY_ID: AWS Access Key ID.
AWS_SECRET_ACCESS_KEY: AWS Secret Access Key.
KUBE_CONFIG_DATA: Base64-encoded Kubeconfig data for accessing the EKS cluster.


### AWS Credentials Setup
To set up AWS credentials, store your AWS Access Key and Secret Key as GitHub Secrets:

Navigate to your GitHub repository.
Go to Settings > Secrets > New repository secret.
Add the following secrets:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

### Kubernetes Configuration
The KUBE_CONFIG_DATA secret is required for configuring kubectl in the pipeline. Follow these steps to generate and store the Kubeconfig:


### Running the Pipeline
Once the pipeline is configured, it will automatically trigger on pushes to the master branch. 

## The 'Destroy' Workflow
After deployment of the sock shop microservices through this well constructed pipeline, resources are been created on the AWS account which warrant a need to delete and cleanup resources after use. 

To solve this, I have created a new workflow called 'destroy.yaml' which cleans up which the aid of using the backend which in this case is S3 which stores the terraform statefile and can there compare the state of the configuration with the actual resource that exist in AWS account. 

### This pipeline follow quite a simple workflow
Starting a New Workflow:

The first step is to initialize Terraform using terraform init.
During initialization, Terraform connects to the S3 backend and downloads the existing state file. This gives Terraform a full understanding of what resources have been created, even if they were created in a different workflow.
#### Running terraform destroy:

Now, when terraform destroy is ran, Terraform compares the state file (downloaded from S3) with the current state of your infrastructure and identifies which resources it needs to destroy.
Since the state file reflects the resources managed by Terraform, it knows exactly what to delete.
