package main

func main() {
	configuration := NewConfigurationFromEnv()
	terminalBridge := NewTerminalBridge(configuration)
	requestHandler := NewRequestHandler(terminalBridge)
	requestHandler.HandleRequests()
}
