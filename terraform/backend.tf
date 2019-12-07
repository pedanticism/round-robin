terraform {
  backend "s3" {
    bucket = "pedanticism-terraform-state"
    key    = "round-robin"
    region = "eu-west-1"
  }
}