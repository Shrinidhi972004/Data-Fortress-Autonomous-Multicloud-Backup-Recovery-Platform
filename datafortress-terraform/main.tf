resource "aws_s3_bucket" "datafortress" {
  bucket = var.bucket_name
  tags = {
    Name        = "DataFortressBackup"
    Environment = "Dev"
    Owner       = "Shrinidhi"
    Project     = "Data Fortress"
  }
}

# Enable versioning (keeps multiple versions of same file)
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.datafortress.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable default server-side encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.datafortress.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access (safety)
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.datafortress.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
