#! /bin/bash
set -e

if [ -z "$1" ]; then
    echo "usage: ./create.sh <config.tfvars.json>"
    exit 1
fi

NAME=$(cat "$1" | jq -r .env_name)
PROJECT=$(cat "$1" | jq -r .project)
ZONE=$(cat "$1" | jq -r .zone)
DOMAIN=$(cat "$1" | jq -r .env_dns_domain)

OUTPUT_DIR="$NAME-state"
CONFIG_VALS_DIR="$OUTPUT_DIR"/config-values
TFSTATE="$OUTPUT_DIR/$NAME.tfstate"

mkdir -p $OUTPUT_DIR $CONFIG_VALS_DIR

terraform init terraform
terraform apply --var-file "$1" --state "$TFSTATE" terraform

STATIC_IP=$(terraform output -json --state="$TFSTATE" | jq -r .lb_static_ip.value)
GCR_KEY=$(terraform output -json --state="$TFSTATE" | jq -r .gcr_key.value)

gcloud container clusters get-credentials $NAME --zone $ZONE --project $PROJECT

git clone https://github.com/cloudfoundry/cf-for-k8s || true

./cf-for-k8s/hack/generate-values.sh -d $DOMAIN > $CONFIG_VALS_DIR/cf-values.yml

cat << YAML > $CONFIG_VALS_DIR/static-ip.yml
#@data/values
---
istio_static_ip: $STATIC_IP
YAML


cat << YAML > $CONFIG_VALS_DIR/app-registry.yaml
#@data/values
---
app_registry:
  hostname: "gcr.io"
  repository_prefix: "gcr.io/$PROJECT/$NAME/cf-workloads"
  username: "_json_key"
  password: |
$(echo "$GCR_KEY" | sed 's/^/    /g')
YAML

kapp deploy -a cf -f <(ytt -f cf-for-k8s/config -f $CONFIG_VALS_DIR) -y

SYS_DOMAIN=$(bosh int $CONFIG_VALS_DIR/cf-values.yml --path /system_domain)
CF_PASSWORD=$(bosh int $CONFIG_VALS_DIR/cf-values.yml --path /cf_admin_password)

cf login \
  -a "https://api.$SYS_DOMAIN" \
  --skip-ssl-validation \
  -u admin \
  -p "$CF_PASSWORD"

cf create-org test-org
cf create-space -o test-org test-space
cf target -o test-org -s test-space

cf push test-app -p cf-for-k8s/tests/smoke/assets/test-node-app

head $CONFIG_VALS_DIR/cf-values.yml

