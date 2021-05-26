# AWS kub cluster module

Terraform module for bootstrapping a Kubernetes cluster with kubeadm on AWS.

## Contents

- [**Description**](#description)
- [**Quick start**](#quick-start)
- [**Prerequisites**](#prerequisites)
- [**AWS resources**](#aws-resources)

## Description

This module allows to create AWS infrastructure and bootstrap a Kubernetes cluster on it with a single command.

Running the module results in a freshly bootstrapped Kubernetes cluster — like what you get after manually bootstrapping a cluster with `kubeadm init` and `kubeadm join`.

The number and types of nodes, the Pod network CIDR block, and many other parameters are configurable.

Notes:

- The module does not install any CNI plugin in the cluster, which reflects the behaviour of kubeadm
- For now, the created clusters are limited to a single master node

## Quick start

First, ensure the [prerequisites](#prerequisites) below.

A minimal usage of the module looks as follows:

```hcl
provider "aws" {
  region = "ap-southeast-1"
}

module "cluster" {
  source           = "./kube_cluster1"
}
```

Running `terraform apply` with this configuration results in the creation of a Kubernetes cluster with one master node and two worker nodes in one of the default subnets of the default VPC of the `ap-southeast-1` region.

The cluster is given a random name (e.g. `relaxed-ocelot`).

You can use this kubeconfig file to access the cluster. For example:

```bash
kubectl --kubeconfig relaxed-ocelot.conf get nodes
```

> Note that if you execute the above command, you will see that all nodes are `NotReady`. This is the expected behaviour because the cluster does not yet have a CNI plugin installed.

> Note that when you delete the cluster with `terraform destroy`, the kubeconfig file is currently not automatically deleted, thus you have to clean it up yourself if you don't want to have it sticking around.

The module also sets up SSH access to the nodes of the cluster. By default, it uses the OpenSSH default key pair consisting of `~/.ssh/id_rsa` (private key) and `~/.ssh/id_rsa.pub` (public key) on your local machine for this. Thus, you can connect to the nodes of the cluster as follows:

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<PUBLIC-IP>
```

The public IP addresses of all the nodes are specified in the output of the module, which you can display with `terraform output`.

## Prerequisites

The module depends on the following prerequisites:

### 1. Install Terraform

[Installing Terraform](https://www.terraform.io/downloads.html) is done by simply downloading the Terraform binary for your target platform from the Terraform website and moving it to any directory in your `PATH`.


Terraform needs to have access to the **AWS Access Key ID** and **AWS Secret Access Key** of your AWS account in order to create AWS resources.

You can achieve this in one of the two following ways:

-  Create an [`~/.aws/credentials`](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-where) file. This is automatically done for you if you configure the [AWS CLI](https://aws.amazon.com/cli/):

    ```bash
    aws configure
    ```

- Set the [`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) environment variables to your Access Key ID and Secret Access Key:

    ```bash
    export AWS_ACCESS_KEY_ID=<AccessKeyID>
    export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
    ```

### 3. Set up OpenSSH

The module depends on the `ssh` and `scp` tools being installed on your local machine. These tools are installed by default on most systems as part of the [OpenSSH](https://www.openssh.com/) package. In the unlikely case that OpenSSH isn't installed on your system, you can install it with:

```bash
# Linux
sudo apt-get install openssh-client

Furthermore, the module by default uses the default OpenSSH key pair consisting of `~/.ssh/id_rsa` (private key) and `~/.ssh/id_rsa.pub` (public key) for setting up SSH access to the nodes of the cluster.

If you currently don't have this key pair on your system, you can generate it by running:

```bash
ssh-keygen
```

Note that `~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub` are just default values and you can specify a different key pair to the module (with the `private_key_file` and `public_key_file` variables).

For example, you can generate a dedicated key pair for your cluster with:

```bash
ssh-keygen -f my-key
```

Which creates two files named `my-key` (private key) and `my-key.pub` (public key), which you can then specify to the corresponding input variables of the module.

## AWS resources

With the default settings (1 master node and 2 worker nodes), the module creates the following AWS resources:

| Explicitly created        | Implicitly created (default sub-resources)                          |
|---------------------------|---------------------------------------------------------------------|
| 4 [Security Groups][sg]   |                                                                     |
| 1 [Key Pair][key]         |                                                                     |
| 1 [Elastic IP][eip]       |                                                                     |
| 3 [EC2 Instances][i]      | 3 [Volumes][vol], 3 [Network Interfaces][eni]                       |

**Total: 14 resources**

[sg]: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html
[eip]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
[i]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html
[vol]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEBS.html
[eni]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html
[key]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html

Note that each node results in the creation of 3 AWS resources: 1 EC2 instance, 1 Volume, and 1 Network Interface. Consequently, you can add or subtract 3 from the total number of created AWS resources for each added or removed worker node. For example:

- 1 worker node: total 12 AWS resources
- 2 worker nodes: total 15 AWS resources
- 3 worker nodes: total 18 AWS resources

You can list all AWS resources in a given region with the [Tag Editor](https://console.aws.amazon.com/resource-groups/tag-editor) in the AWS Console.

> Note that [Key Pairs][key] are not listed in the Tag Editor.

### Tags

The module assigns a tag with a key of `kubeadm:cluster` and a value corresponding to the cluster name to all explicitly created resources. For example, if the cluster name is `relaxed-ocelot`, all of the above explicitly created resources will have the following tag:

```
kubeadm:cluster=relaxed-ocelot
```

This allows you to easily identify the resources that belong to a given cluster.

> Note that the implicitly created sub-resources (such as the Volumes and Network Interfaces of the EC2 Instances) won't have the `kubeadm:cluster` tag assigned.

Additionally, the EC2 instances will get a tag with a key of `kubeadm:node` and a value corresponding to the Kubernetes node name. For the master node, this is:

```
kubeadm:node=master
```

And for the worker nodes:

```
kubeadm:node=worker-X
```

Where `X` is an index starting at 0.

## Network submodule

By default, the kubeadm module creates the cluster in the [default VPC](https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html) of the specified AWS region.

# TWO Jenkins Pipelines used to build the helloworldapp


-- Pipeline_Build_Kuberenetes_Cluster - To build the Kube Cluster
-- Pipeline_HelloWorldApp             - To create helloworld web ap using Docker file and K8s container

# Process

Build Docker Image --> Push Docker Image --> Build KUBE Cluster --> Deploy Web App called 'HelloWorldApp'
