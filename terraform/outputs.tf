output "public_ip" {
  description = "Elastic IP attached to the instance."
  value       = aws_eip.this.public_ip
}

output "public_dns" {
  description = "AWS-assigned public DNS name."
  value       = aws_instance.this.public_dns
}

output "ssh_command" {
  description = "Convenience SSH command (assumes the matching private key)."
  value       = "ssh ubuntu@${aws_eip.this.public_ip}"
}

output "deployment" {
  description = "Per-deployment identifier (environment + random suffix). Matches the Deployment tag and the user-namespace names of the key pair and security group."
  value       = local.deployment
}

output "hostname" {
  description = "Public hostname. Under 'direct' fronting a Route53 A record points it at the EIP; under 'cloudflare' fronting it is a Cloudflare-fronted CNAME whose origin (managed out-of-band) must be pointed at public_ip."
  value       = local.hostname
}

output "hub_url" {
  description = "JupyterHub URL once cloud-init finishes (and, under 'cloudflare' fronting, once the Cloudflare origin is repointed at the EIP)."
  value       = "https://${local.hostname}"
}

output "fronting" {
  description = "Fronting mode of this deployment ('direct' or 'cloudflare')."
  value       = var.fronting
}
