output "bucket_name" {
  description = "The name of the created S3 bucket"
  value       = aws_s3_bucket.datafortress.bucket
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.datafortress.arn
}
