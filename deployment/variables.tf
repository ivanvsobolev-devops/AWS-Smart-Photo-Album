
variable "default_tags" {
  ProjectName = "AWS Smart Photo Album"
  Owner = "Ivan Sobolev"
}


variable "elk_domain" {
  default = "photos"
}


variable "LF1_payload_name" {
  default = "lambda_index_photos_payload.zip"
}

variable "LF2_payload_name" {
  default = "lambda_search_payload.zip"
}