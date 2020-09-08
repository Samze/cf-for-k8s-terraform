resource "google_service_account" "gcr-account" {
  project = var.project
  account_id   = "${var.env_name}-gcr-sa"
  display_name = "terraform created account to access gcr readonly"
}

resource "google_project_iam_member" "gce-gcr-account-project-iam-member" {
  role               = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.gcr-account.email}"
}

resource "google_service_account_key" "gcr-account-key" {
  service_account_id = google_service_account.gcr-account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
