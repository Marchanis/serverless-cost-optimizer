terraform  {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }

    backend "s3" {
        bucket = "serverless-cost-optimizer-state-soso"
        key    = "serverless-cost-optimizer/terraform.tfstate"
        region = "us-east-1"
        use_lockfile = true
        encrypt = true
    }
    required_version = ">= 1.5.0"
}