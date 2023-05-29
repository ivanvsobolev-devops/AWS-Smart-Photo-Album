output "frontend_fqdn" {
  value = aws_s3_bucket_website_configuration.album_frontend.website_domain
}

output "frontend_endpoint" {
  value = aws_s3_bucket_website_configuration.album_frontend.website_endpoint
}