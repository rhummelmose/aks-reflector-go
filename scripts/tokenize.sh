#!/bin/bash

# Debugging
if [ ! -z $TOKENIZE_DEBUG ]; then
    echo "Setting debugging variables.."
    ARGO_SP_USERNAME=debug_username
    ARGO_AZURE_AD_TENANT=debug_tenant
    ARGO_RESOURCE_GROUP=debug_resource_group
    ARGO_AKS_CLUSTER_NAME=debug_aks_cluster_name
    ARGO_LISTENING_PORT=debug_listening_port
    ARGO_SP_PASSWORD=debug_password
    AZDEV_BUILD_SOURCE_VERSION=debug_azdev_build_source_version
fi

# Validate required variables
if [ -z $ARGO_SP_USERNAME ] || \
   [ -z $ARGO_AZURE_AD_TENANT ] || \
   [ -z $ARGO_RESOURCE_GROUP ] || \
   [ -z $ARGO_AKS_CLUSTER_NAME ] || \
   [ -z $ARGO_LISTENING_PORT ] || \
   [ -z $ARGO_SP_PASSWORD ] || \
   [ -z $AZDEV_BUILD_SOURCE_VERSION ]; then
    echo "Required variables missing from env.."
    printf "ARGO_SP_USERNAME: %s" $ARGO_SP_USERNAME
    printf "ARGO_AZURE_AD_TENANT: %s" $ARGO_AZURE_AD_TENANT
    printf "ARGO_RESOURCE_GROUP: %s" $ARGO_RESOURCE_GROUP
    printf "ARGO_AKS_CLUSTER_NAME: %s" $ARGO_AKS_CLUSTER_NAME
    printf "ARGO_LISTENING_PORT: %s" $ARGO_LISTENING_PORT
    printf "AZDEV_BUILD_SOURCE_VERSION: %s" $AZDEV_BUILD_SOURCE_VERSION
    if [ -z $ARGO_SP_PASSWORD ]; then
        echo "ARGO_SP_PASSWORD: *****"
    else
        echo "ARGO_SP_PASSWORD: <empty>"
    fi
    exit 1
fi

# Install pre-reqs (requires snap)
install_prereqs() {
    local yq_installed
    yq --version > /dev/null 2>&1
    yq_installed=$?
    if [ $yq_installed -ne 0 ]; then
        sudo snap install yq
    fi
}

install_prereqs


# Quote/escape functions for sed

quoteRe() {
    sed -e 's/[^^]/[&]/g; s/\^/\\^/g; $!a\'$'\n''\\n' <<<"$1" | tr -d '\n';
}

quoteSubst() {
  IFS= read -d '' -r < <(sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g' <<<"$1")
  printf %s "${REPLY%$'\n'}"
}

# Template SED
# sed -i '' s/$(quoteRe "$key")/$(quoteSubst "$value")/g file.ext

# Template YQ
# yq w --inplace file.ext path.to.thing "$value"

# configmaps.yml
yq w --inplace kubernetes/configmaps.yml "data.sp-username" "\"$ARGO_SP_USERNAME\""
yq w --inplace kubernetes/configmaps.yml "data.azure-ad-tenant" "\"$ARGO_AZURE_AD_TENANT\""
yq w --inplace kubernetes/configmaps.yml "data.resource-group" "\"$ARGO_RESOURCE_GROUP\""
yq w --inplace kubernetes/configmaps.yml "data.aks-cluster-name" "\"$ARGO_AKS_CLUSTER_NAME\""
yq w --inplace kubernetes/configmaps.yml "data.listening-port" "\"$ARGO_LISTENING_PORT\""

# secrets.yml
yq w --inplace kubernetes/secrets.yml "data.sp-password" "\"$(printf '%s' $ARGO_SP_PASSWORD | base64)\""

#deployments.yml
image_name=$(yq r kubernetes/deployments.yml "spec.template.spec.containers[0].image")
image_tag="$AZDEV_BUILD_SOURCE_VERSION"
container_image="${image_name}:${image_tag}"
label_source_version="source_version"
yq w --inplace kubernetes/deployments.yml "spec.template.spec.containers[0].image" "\"$container_image\""
yq w --inplace kubernetes/deployments.yml "spec.template.spec.containers[0].ports[0].containerPort" "$ARGO_LISTENING_PORT"
yq w --inplace kubernetes/deployments.yml "metadata.labels[$label_source_version]" "\"$AZDEV_BUILD_SOURCE_VERSION\""
yq w --inplace kubernetes/deployments.yml "spec.selector.matchLabels[$label_source_version]" "\"$AZDEV_BUILD_SOURCE_VERSION\""
yq w --inplace kubernetes/deployments.yml "spec.template.metadata.labels[$label_source_version]" "\"$AZDEV_BUILD_SOURCE_VERSION\""

# services.yml
yq w --inplace kubernetes/services.yml "spec.ports[0].port" $ARGO_LISTENING_PORT

# ingresses.yml
yq w --inplace kubernetes/ingresses.yml "spec.rules[0].http.paths[0].backend.servicePort" "$ARGO_LISTENING_PORT"
