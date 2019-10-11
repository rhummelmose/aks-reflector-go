package main

import (
	"os"
)

// Configuration holds configuration for the aks-window application
type Configuration struct {
	ServicePrincipalUsername string
	ServicePrincipalPassword string
	AzureADTenant			 string
	ResourceGroup            string
	AKSClusterName           string
}

// NewConfigurationFromEnv returns a configuration object built by retrieving values from env
func NewConfigurationFromEnv() Configuration {
	var configuration Configuration
	configuration.ServicePrincipalUsername = os.Getenv("AW_SP_USERNAME")
	configuration.ServicePrincipalPassword = os.Getenv("AW_SP_PASSWORD")
	configuration.AzureADTenant = os.Getenv("AW_AZURE_AD_TENANT")
	configuration.ResourceGroup = os.Getenv("AW_RESOURCE_GROUP")
	configuration.AKSClusterName = os.Getenv("AW_AKS_CLUSTER_NAME")
	return configuration
}
