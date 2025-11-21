# Route53 Hosted Zone (if you own a domain)
data "aws_route53_zone" "main" {
  count = var.create_dns ? 1 : 0
  name  = var.domain_name
}

# A Record pointing to Elastic IP
resource "aws_route53_record" "chatter" {
  count   = var.create_dns ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = "300"
  records = [aws_eip.chatter.public_ip]
}

# WWW CNAME Record
resource "aws_route53_record" "www" {
  count   = var.create_dns ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_route53_record.chatter[0].fqdn]
}
