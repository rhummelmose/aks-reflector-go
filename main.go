package main

func main() {
	configuration := NewConfigurationFromEnv()
	terminalBridge := NewTerminalBridge(configuration)
	requestHandler := NewRequestHandler(configuration, terminalBridge)
	requestHandler.HandleRequests()
}
