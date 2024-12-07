data "aws_availability_zones" "us_az_zone" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}