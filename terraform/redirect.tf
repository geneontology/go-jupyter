# Optional hostname forward: redirect_hostname -> redirect_target_url (HTTP 302).
# See the variable comments in variables.tf. Everything here is created only when
# redirect_hostname and redirect_target_url are both set.

locals {
  redirect_enabled = var.redirect_hostname != null && var.redirect_target_url != null
  redirect_zone    = coalesce(var.redirect_zone_name, var.route53_zone_name)
  # CloudFront needs an origin even though the function answers every request.
  redirect_target_host = local.redirect_enabled ? regex("^https?://([^/]+)", var.redirect_target_url)[0] : ""
}

data "aws_route53_zone" "redirect" {
  count        = local.redirect_enabled ? 1 : 0
  name         = local.redirect_zone
  private_zone = false
}

resource "aws_acm_certificate" "redirect" {
  count             = local.redirect_enabled ? 1 : 0
  region            = "us-east-1" # CloudFront only accepts certificates from us-east-1
  domain_name       = var.redirect_hostname
  validation_method = "DNS"
  tags              = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "redirect_validation" {
  for_each = local.redirect_enabled ? {
    for dvo in aws_acm_certificate.redirect[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = data.aws_route53_zone.redirect[0].zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "redirect" {
  count                   = local.redirect_enabled ? 1 : 0
  region                  = "us-east-1"
  certificate_arn         = aws_acm_certificate.redirect[0].arn
  validation_record_fqdns = [for r in aws_route53_record.redirect_validation : r.fqdn]
}

resource "aws_cloudfront_function" "redirect" {
  count   = local.redirect_enabled ? 1 : 0
  name    = "go-jupyter-forward-${replace(var.redirect_hostname, ".", "-")}"
  runtime = "cloudfront-js-2.0"
  publish = true
  comment = "302 ${var.redirect_hostname} -> ${var.redirect_target_url} (path and query preserved)"
  tags    = local.tags
  code    = <<-EOT
    function handler(event) {
      var req = event.request;
      var qs = [];
      for (var k in req.querystring) {
        var v = req.querystring[k];
        if (v.multiValue) {
          for (var i = 0; i < v.multiValue.length; i++) { qs.push(k + "=" + v.multiValue[i].value); }
        } else {
          qs.push(v.value === "" ? k : k + "=" + v.value);
        }
      }
      var location = "${var.redirect_target_url}" + req.uri + (qs.length ? "?" + qs.join("&") : "");
      return {
        statusCode: 302,
        statusDescription: "Found",
        headers: {
          "location": { "value": location },
          "cache-control": { "value": "no-store" }
        }
      };
    }
  EOT
}

resource "aws_cloudfront_distribution" "redirect" {
  count           = local.redirect_enabled ? 1 : 0
  enabled         = true
  is_ipv6_enabled = true
  comment         = "go-jupyter: forward ${var.redirect_hostname} -> ${var.redirect_target_url}"
  aliases         = [var.redirect_hostname]
  price_class     = "PriceClass_100"
  tags            = local.tags

  origin {
    domain_name = local.redirect_target_host
    origin_id   = "forward-target"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "forward-target"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    # AWS managed policy "CachingDisabled".
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect[0].arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.redirect[0].certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "redirect_a" {
  count   = local.redirect_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.redirect[0].zone_id
  name    = var.redirect_hostname
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.redirect[0].domain_name
    zone_id                = aws_cloudfront_distribution.redirect[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "redirect_aaaa" {
  count   = local.redirect_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.redirect[0].zone_id
  name    = var.redirect_hostname
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.redirect[0].domain_name
    zone_id                = aws_cloudfront_distribution.redirect[0].hosted_zone_id
    evaluate_target_health = false
  }
}

output "redirect_url" {
  description = "The forwarding hostname, when configured."
  value       = local.redirect_enabled ? "https://${var.redirect_hostname} -> ${var.redirect_target_url}" : null
}
