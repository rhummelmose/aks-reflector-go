package main

import (
	"fmt"
	"encoding/json"
	"log"
	"net/http"
)

// RequestHandler handles HTTP requests
type RequestHandler struct {
	configuration Configuration
	terminalBridge TerminalBridge
}

// NewRequestHandler returns a new request handler configured to use a terminal bridges
func NewRequestHandler(configuration Configuration, terminalBridge TerminalBridge) RequestHandler {
	var requestHandler RequestHandler
	requestHandler.configuration = configuration
	requestHandler.terminalBridge = terminalBridge
	return requestHandler
}

// HandleRequests starts the request handler
func (rh *RequestHandler) HandleRequests() {
	http.HandleFunc("/cluster", rh.handleClusterRequest)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", rh.configuration.ListeningPort), nil))
}

func (rh *RequestHandler) handleClusterRequest(w http.ResponseWriter, r *http.Request) {
	clusterInfo := rh.terminalBridge.RetrieveClusterInfo()
	result, encodingErr := json.Marshal(clusterInfo)
	if encodingErr != nil {
		log.Fatal(encodingErr)
	}
	w.Write(result)
	fmt.Println("Endpoint Hit: cluster")
}
