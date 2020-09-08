Creates a cf-for-k8s env on GKE using terraform.

### How to use

To install:
1. Login with `gcloud auth application-default login`
1. Edit `example.tfvars.json` with your GCP values. Changing at a minimum `env_name`, `env_dns_domain`, `region` & `zone`.
1. Run `./create.sh config.tfvars.json`

To cleanup:
1. `terraform destroy --var-file config.tfvars.json --state=<output_file.tfstate> terraform`

### Required CLI dependencies
* terraform
* bosh
* kapp / ytt
* gcloud
* cf

### Notes
Terraform modified from https://github.com/cloudfoundry/cf-for-k8s/tree/master/deploy/gke/terraform

