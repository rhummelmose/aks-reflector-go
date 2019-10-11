package main

import (
	"log"
	"strconv"
	"os"
)

// Configuration holds configuration for the aks-window application
type Configuration struct {
	ServicePrincipalUsername string
	ServicePrincipalPassword string
	AzureADTenant			 string
	ResourceGroup            string
	AKSClusterName           string
	ListeningPort            int
}

// NewConfigurationFromEnv returns a configuration object built by retrieving values from env
func NewConfigurationFromEnv() Configuration {
	var configuration Configuration
	configuration.ServicePrincipalUsername = os.Getenv("AWGO_SP_USERNAME")
	configuration.ServicePrincipalPassword = os.Getenv("AWGO_SP_PASSWORD")
	configuration.AzureADTenant = os.Getenv("AWGO_AZURE_AD_TENANT")
	configuration.ResourceGroup = os.Getenv("AWGO_RESOURCE_GROUP")
	configuration.AKSClusterName = os.Getenv("AWGO_AKS_CLUSTER_NAME")
	listeningPort, listeningPortErr := strconv.Atoi(os.Getenv("AWGO_LISTENING_PORT"))
	if listeningPortErr != nil {
		log.Fatal(listeningPortErr)
	}
	configuration.ListeningPort = listeningPort
	return configuration
}
