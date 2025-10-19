variable "aws_region" {
    description = "AWS region where the s3 bucket will be created"
    type = string
    default = "ap-south-1"
}

variable "bucket_name" {
    description = "Unique name for the s3 bucket"
    type = string
    default = "datafortress-backups-shrinidhi"
}