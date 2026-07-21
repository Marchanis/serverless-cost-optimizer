variable "aws_region" {
    description = "the aws region to deploy the resources"
    type = string
    default = "us-east-1" 
}


variable "sns_email"{
    description = "the email address to send the sns alerts"
    type = string
    sensitive = true
}