# AWS EKS Terraform Project

This project provides a complete Terraform setup for provisioning an Amazon Elastic Kubernetes Service (EKS) cluster on AWS. It includes the necessary infrastructure for networking (VPC, subnets, NAT gateways, etc.) and the EKS cluster itself with node groups.

---

## Project Structure

<img width="521" height="386" alt="Screenshot 2025-09-19 at 19 45 25" src="https://github.com/user-attachments/assets/8d33b115-86c9-4511-8765-7c31549c037f" />

- **`aws-eks-terraform/`**: Root directory of the project.
  - **`.terraform/`**: Contains Terraform state and provider information.
  - **`backend/`**: Contains Terraform configuration for the S3 backend to store state remotely.
    - `main.tf`: Defines the S3 bucket for state storage.
    - `outputs.tf`: Outputs the name of the S3 bucket.
    - `.terraform.lock.hcl`: Provider lock file for the backend.
    - `terraform.tfstate`: Current Terraform state file (if not using remote backend).
    - `terraform.tfstate.backup`: Backup of the Terraform state file.
  - **`modules/`**: Contains reusable Terraform modules.
    - **`vpc/`**: Module for provisioning the VPC and related networking resources.
      - `main.tf`: Defines VPC, subnets, internet gateway, NAT gateways, and route tables.
      - `outputs.tf`: Outputs VPC ID and subnet IDs.
      - `variables.tf`: Input variables for the VPC module.
      - `.terraform/` and `.terraform.lock.hcl`: Provider lock file for the VPC module.
    - **`eks/`**: Module for provisioning the EKS cluster and node groups.
      - `main.tf`: Defines IAM roles, EKS cluster, and EKS node groups.
      - `outputs.tf`: Outputs the EKS cluster endpoint.
      - `variables.tf`: Input variables for the EKS module.
  - **`main.tf`**: Main Terraform configuration file that orchestrates the VPC and EKS modules.
  - **`outputs.tf`**: Outputs the EKS cluster endpoint.
  - **`variables.tf`**: Defines input variables for the root module.
  - **`terraform.tfvars`**: File containing the actual values for the input variables.
  - **`.terraform.lock.hcl`**: Provider lock file for the root module.
  - **`README.md`**: This file.

---

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Terraform**: Install Terraform from the [official website](https://www.terraform.io/downloads.html).
2.  **AWS CLI**: Install and configure the AWS Command Line Interface with your AWS credentials. Ensure your AWS user has sufficient permissions to create EKS clusters, VPCs, S3 buckets, and other necessary resources.
    *   You can configure your AWS credentials by running `aws configure`.
3.  **kubectl**: Install `kubectl` to interact with your EKS cluster. Follow the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for installation instructions.
4.  **AWS Account**: An active AWS account with appropriate IAM permissions.

## Configuration

### AWS Credentials

The Terraform configuration will use your AWS credentials configured via the AWS CLI. Ensure that your configured AWS profile has the necessary permissions to create and manage EKS clusters, VPCs, S3 buckets, and other related resources.

### Terraform Backend Configuration

This project is configured to use an S3 bucket for storing Terraform state remotely. This is crucial for collaboration and for preventing state drift.

-   **`backend/main.tf`**: Defines the S3 bucket named `eks-retail-sample-app-bucket`.
-   **`backend/.terraform.tfstate`**: This file might be present if the backend was initialized locally first. For production, it's best to rely on the remote state.

**Before applying, ensure the S3 bucket `eks-retail-sample-app-bucket` exists in your AWS account and region (`us-east-1`). If it doesn't exist, you can create it manually or uncomment and adapt the `aws_s3_bucket` resource in `backend/main.tf` and apply it separately.**

### Terraform Variables

The project uses Terraform variables to allow for customization. The values for these variables are provided in `terraform.tfvars`.

-   **`vpc_cidr`**: The CIDR block for your VPC.
-   **`public_subnet_cidr`**: A list of CIDR blocks for your public subnets.
-   **`private_subnet_cidr`**: A list of CIDR blocks for your private subnets.

<img width="1509" height="687" alt="Screenshot 2025-09-19 at 20 17 56" src="https://github.com/user-attachments/assets/39968757-6b67-4178-a6ba-ebcda7987171" />

-   **`region`**: The AWS region where resources will be deployed.
-   **`availability_zones`**: A list of availability zones to use within the specified region.
-   **`eks_cluster_name`**: The desired name for your EKS cluster.
-   **`cluster_version`**: The desired Kubernetes version for your EKS cluster.
-   **`node_groups`**: Configuration for EKS node groups, including instance types, capacity type, and scaling settings.

**You can modify the values in `terraform.tfvars` to match your specific requirements.**

## Deployment Steps

Follow these steps to deploy your EKS infrastructure:

1.  **Initialize Terraform**:
    Navigate to the root directory of the project (`aws-eks-terraform/`) and run:
    ```bash
    terraform init
    ```
    This command downloads the necessary providers and prepares your backend configuration.

2.  **Review the Execution Plan**:
    Before applying any changes, review the plan to understand what Terraform will create, modify, or destroy:
    ```bash
    terraform plan
    ```
    This command will show you a detailed overview of the infrastructure changes.

3.  **Apply the Terraform Configuration**:
    If the execution plan looks correct, apply the configuration to create the EKS cluster and its associated resources:
    ```bash
    terraform apply
    ```
    Terraform will prompt you to confirm the apply. Type `yes` and press Enter to proceed.

---

## Post-Deployment Steps

### Configure `kubectl`

After Terraform has successfully applied the configuration, you'll need to configure `kubectl` to communicate with your new EKS cluster.

1.  **Update `kubeconfig`**:
    The EKS cluster endpoint and certificate authority data are outputted by Terraform. You can use the AWS CLI to update your `kubeconfig` file:

    ```bash
    aws eks --region us-east-1 update-kubeconfig --name project-bedrock
    ```
    Replace `<your-region>` with the AWS region you specified in `terraform.tfvars` (e.g., `us-east-1`) and `<your-cluster-name>` with the name of your EKS cluster (e.g., `project-bedrock`).

2.  **Verify `kubectl` Connection**:
    Test your `kubectl` connection to the cluster:
    ```bash
    kubectl get svc
    ```
    This command should list the services in your cluster, including the default Kubernetes services.

---

## Deployment of the Retail Sample APP

This deployment method will run the application in an existing Kubernetes cluster.

### Pre-requisites:

*   Kubernetes cluster
*   `kubectl` installed locally

### Deployment Steps:

1.  **Deploy the application using `kubectl`**:
    ```bash
    kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml
    ```

2.  **Wait for all deployments to become available**:
    ```bash
    kubectl wait --for=condition=available deployments --all
    ```

3.  **Retrieve the frontend load balancer URL**:
    ```bash
    kubectl get svc ui
    ```
    The output of this command will provide the external URL for the frontend load balancer.

---

## Destroying the Infrastructure

When you no longer need the EKS cluster and its associated resources, you can destroy them to avoid incurring further AWS charges.

1.  **Destroy Terraform Resources**:
    Navigate to the root directory of the project (`aws-eks-terraform/`) and run:
    ```bash
    terraform destroy
    ```
    Terraform will show you a plan of the resources to be destroyed and ask for confirmation. Type `yes` and press Enter to proceed.

    **Note**: Ensure that your S3 backend state is properly managed. If you have versioning or other settings on your S3 bucket, they might affect the destruction process.

## Important Considerations

-   **IAM Permissions**: The IAM user or role running Terraform must have sufficient permissions to create and manage all the AWS resources defined in this project.
-   **State Management**: Using an S3 backend with DynamoDB for locking is highly recommended for production environments to ensure state consistency and prevent concurrent modifications.
-   **Security Groups**: Pay close attention to the security group configurations within the VPC module to ensure proper network access control for your EKS cluster and nodes.
-   **Cost**: Be mindful of the AWS costs associated with running EKS clusters and related resources. Remember to destroy the infrastructure when it's no longer needed.
-   **Provider Versions**: The `.terraform.lock.hcl` files ensure that you are using the exact provider versions specified, which helps in maintaining consistent deployments.

---

## Creating a Read-Only User for EKS

This section outlines the steps to create an IAM user with read-only access to your EKS cluster. This is useful for granting visibility to users or applications without allowing them to make changes.

### Steps:

1.  **Create an IAM Policy:**
    Define an IAM policy that grants `eks:Describe*` and `eks:List*` permissions. You can use the provided `eks-developer-readonly.json` file for this purpose.

    ```json
    aws-iam create-policy --policy-name EKSDeveloperReadOnlyPolicy --policy-document file://path/to/eks-developer-readonly.json
    ```
    *Note: Replace `path/to/eks-developer-readonly.json` with the actual path to the file.*

2.  **Create an IAM User:**
    Create a new IAM user that will have read-only access.

    ```bash
    aws iam create-user --user-name developer-readonly
    ```

3.  **Attach the IAM Policy to the User:**
    Attach the read-only policy created in Step 1 to the `developer-readonly` user.

    ```bash
    aws iam attach-user-policy --user-name developer-readonly --policy-arn arn:aws:iam::932263135322:policy/EKSDeveloperReadOnlyPolicy
    ```
    *Note: Replace `932263135322` with your AWS account ID if it differs.*

4.  **Create a Kubernetes ClusterRole:**
    Define a Kubernetes `ClusterRole` that grants `get`, `list`, and `watch` permissions on all API groups and resources. This is defined in `read-only-clusterrole.yaml`.

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: read-only-clusterrole
    rules:
    - apiGroups: ["*"]
      resources: ["*"]
      verbs: ["get", "list", "watch"]
    ```

5.  **Create an IAM Identity Mapping:**
    Use `eksctl` to create an IAM identity mapping, associating the IAM user with a Kubernetes group. This allows the IAM user to assume the role of a user within a specific group in Kubernetes. The provided script `iamidentitymapping.sh` can be used for this.

    ```bash
    eksctl create iamidentitymapping \
      --cluster project-bedrock \
      --region us-east-1 \
      --arn "arn:aws:iam::932263135322:user/developer-readonly" \
      --username "developer-readonly" \
      --group "read-only-group"
    ```
    *Note: Ensure `project-bedrock` is your cluster name and `us-east-1` is your cluster region.*

6.  **Create a ClusterRoleBinding:**
    Create a `ClusterRoleBinding` to bind the `read-only-group` (created in the previous step) to the `read-only-clusterrole` (defined in Step 4). This is defined in `read-only-clusterrolebinding.yaml`.

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: read-only-clusterrolebinding
    subjects:
    - kind: Group
      name: "read-only-group" # This name must match the group name used in Step 5
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: ClusterRole
      name: read-only-clusterrole # This name must match the ClusterRole created in Step 4
      apiGroup: rbac.authorization.k8s.io
    ```

After completing these steps, the `developer-readonly` IAM user will be able to access the EKS cluster with read-only permissions.

---

--

## Important Considerations

-   **IAM Permissions**: The IAM user or role running Terraform must have sufficient permissions to create and manage all the AWS resources defined in this project.
-   **State Management**: Using an S3 backend with DynamoDB for locking is highly recommended for production environments to ensure state consistency and prevent concurrent modifications.
-   **Security Groups**: Pay close attention to the security group configurations within the VPC module to ensure proper network access control for your EKS cluster and nodes.
-   **Cost**: Be mindful of the AWS costs associated with running EKS clusters and related resources. Remember to destroy the infrastructure when it's no longer needed.

---
