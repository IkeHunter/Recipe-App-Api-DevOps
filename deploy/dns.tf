data "aws_route53_zone" "zone" {
  name = "${var.dns_zone_name}." # ending it in dot is a naming convention
}

resource "aws_route53_record" "app" { # create new record in route53
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.zone.name}"
  type    = "CNAME" # link to existing dns name
  ttl     = 300     # time to live, how long should it take to propogate

  records = [aws_lb.api.dns_name]
}

resource "aws_acm_certificate" "cert" {
  domain_name       = aws_route53_record.app.fqdn # fully qualified domain name
  validation_method = "DNS"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true # keep tf running smooth when destroy
  }
}

resource "aws_route53_record" "cert_validation" {                                              # create validation record to validate ssl
  name    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name # based on output
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type # based on output
  zone_id = data.aws_route53_zone.zone.zone_id
  records = [
    tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value # based certification on output
  ]
  ttl = "60" # shortest
}

resource "aws_acm_certificate_validation" "cert" { # not actual resource, used to trigger validation process
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}