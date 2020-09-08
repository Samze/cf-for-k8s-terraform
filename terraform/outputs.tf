output "lb_static_ip" {
  value = google_compute_address.lb_static_ip.address
}

output "gcr_key" {
  value = base64decode(google_service_account_key.gcr-account-key.private_key)
}
