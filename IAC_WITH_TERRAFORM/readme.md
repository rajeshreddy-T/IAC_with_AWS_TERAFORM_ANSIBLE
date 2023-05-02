Procedure to use terraform to install the instance and configure the instance with ansible.
```
1. Create a folder and copy the files from IAC_WITH_TERRAFORM folder.
2. Run the command terraform init
3. Run the command terraform plan
4. Run the command terraform apply
5. Once the instance is created, run the command ansible-playbook -i hosts playbook.yml
```


terraform installation on an ec2 instance and using that create the VPC and AZ and then create the instance in that VPC and AZ and then configure the instance with ansible.

```
1. Create an ec2 instance and install terraform on that instance.
   commands:
    sudo yum install wget unzip -y
    wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
    unzip terraform_0.12.24_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    terraform --version
2. Create a folder and copy the files from IAC_WITH_TERRAFORM folder.
3. Run the command terraform init
4. Run the command terraform plan
5. Run the command terraform apply
6. Once the instance is created, run the command ansible-playbook -i hosts playbook.yml
```

we can do this in 2 ways either by installing terraform on your local or by installing it in aws ec2 instance


## on local:

1. Install Terraform on your local machine. You can download Terraform from the official Terraform website (https://www.terraform.io/downloads.html).
2. Set up AWS credentials. You'll need to create an AWS access key and secret access key, and then set them as environment variables or in the Terraform configuration file. Here's an example of how to set the credentials as environment variables:
```
export AWS_ACCESS_KEY_ID=(your access key id)
export AWS_SECRET_ACCESS_KEY=(your secret access key)
```
3. Create a directory for your Terraform code and create a file named main.tf in that directory. Copy the Terraform code into main.tf.
4. Run the following commands:
```
terraform init
terraform plan
terraform apply
```
5. When you're done, run terraform destroy to delete the resources that Terraform created.

## on ec2 instance:
1. Create an ec2 instance and install terraform on that instance.
   commands:
    sudo yum install wget unzip -y
    wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
    unzip terraform_0.12.24_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    terraform --version
2. if you dont have accesskey and secret you can use the below code in main.tf file
```
provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "/dev/null"
  profile = "default"
  token = "${chomp(file("/var/run/secrets/aws_iam/security_token"))}"
}

```
3. Create a directory for your Terraform code and create a file named main.tf in that directory. Copy the Terraform code into main.tf.
4. Run the following commands:
```
terraform init
terraform plan
terraform apply
```
5. When you're done, run terraform destroy to delete the resources that Terraform created.

## if you have accesskey and secret you can use the below code in main.tf file
```
provider "aws" {
  region = "us-east-1"
  shared_credentials_file = "/dev/null"
  profile = "default"
  token = "${chomp(file("/var/run/secrets/aws_iam/security_token"))}"
}

```






