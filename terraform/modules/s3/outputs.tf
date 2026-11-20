output "bucket" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.bucket.bucket
}

output "id" {
  description = "The ID of the bucket"
  value       = aws_s3_bucket.bucket.id
}

output "arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.bucket.bucket_domain_name
}

output "objects" {
  description = "The uploaded S3 objects"
  value       = aws_s3_object.object[*]
}
