package main

import (
	"encoding/json"
	"log"
	"os/exec"
)

// TerminalBridge allows interaction with the OS terminal to retrieve AKS cluster information
type TerminalBridge struct {
	configuration Configuration
}

// ClusterInfo holds relevant information about an AKS cluster
type ClusterInfo struct {
	Name     string `json:"name"`
	Location string `json:"location"`
	Pods     []Pod  `json:"pods"`
}

// Pod holds relevant information about a pod
type Pod struct {
	Name   string `json:"name"`
	Images []string `json:"images"`
}

// NewTerminalBridge returns a configured terminal bridge
func NewTerminalBridge(configuration Configuration) TerminalBridge {
	var terminalBridge TerminalBridge
	terminalBridge.configuration = configuration
	terminalBridge.azLogin()
	terminalBridge.azAKSGetCredentials()
	return terminalBridge
}

// RetrieveClusterInfo retrieves terminal information from the terminal
func (tb *TerminalBridge) RetrieveClusterInfo() ClusterInfo {
	var clusterInfo ClusterInfo
	resourceGroup := tb.configuration.ResourceGroup
	name := tb.configuration.AKSClusterName
	azCmd := exec.Command("az", "aks", "show", "--resource-group", resourceGroup, "--name", name)
	azOutput, azErr := azCmd.Output()
	if azErr != nil {
		log.Fatal(azErr)
	}
	if err := json.Unmarshal(azOutput, &clusterInfo); err != nil {
		log.Fatal(err)
	}
	var kubectlPods map[string]interface{}
	kubectlCmd := exec.Command("kubectl", "get", "pods", "--all-namespaces", "--output=json")
	kubectlOutput, kubectlErr := kubectlCmd.Output()
	if kubectlErr != nil {
		log.Fatal(kubectlErr)
	}
	if err := json.Unmarshal(kubectlOutput, &kubectlPods); err != nil {
		log.Fatal(err)
	}
	items := kubectlPods["items"].([]interface{})
	for _, item := range items {
		var pod Pod
		item := item.(map[string]interface{})
		name := item["metadata"].(map[string]interface{})["name"].(string)
		pod.Name = name
		containers := item["spec"].(map[string]interface{})["containers"].([]interface{})
		for _, container := range containers {
			container := container.(map[string]interface{})
			image := container["image"].(string)
			pod.Images = append(pod.Images, image)
		}
		clusterInfo.Pods = append(clusterInfo.Pods, pod)
	}
	return clusterInfo
}

func (tb *TerminalBridge) azLogin() {
	username := tb.configuration.ServicePrincipalUsername
	password := tb.configuration.ServicePrincipalPassword
	tenant := tb.configuration.AzureADTenant
	cmd := exec.Command("az", "login", "--service-principal", "--username", username, "--password", password, "--tenant", tenant)
	log.Printf("Running az login command..")
	output, err := cmd.Output()
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Command finished with result: %s", output)
}

func (tb *TerminalBridge) azAKSGetCredentials() {
	resourceGroup := tb.configuration.ResourceGroup
	name := tb.configuration.AKSClusterName
	cmd := exec.Command("az", "aks", "get-credentials", "--resource-group", resourceGroup, "--name", name, "--admin")
	log.Printf("Running az aks get-credentials command..")
	output, err := cmd.Output()
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Command finished with result: %s", output)
}
