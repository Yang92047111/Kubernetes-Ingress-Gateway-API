package main

import (
	"encoding/json"
	"net/http"
	"time"
)

type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
}

type VersionResponse struct {
	Version   string    `json:"version"`
	BuildTime time.Time `json:"build_time"`
	GoVersion string    `json:"go_version"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	response := HealthResponse{
		Status:    "ok",
		Timestamp: time.Now(),
	}

	json.NewEncoder(w).Encode(response)
}

func versionHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	response := VersionResponse{
		Version:   "1.0.0",
		BuildTime: time.Now(),
		GoVersion: "1.21",
	}

	json.NewEncoder(w).Encode(response)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	response := map[string]interface{}{
		"message": "Welcome to the Kubernetes Routing Experiment",
		"path":    r.URL.Path,
		"method":  r.Method,
		"headers": r.Header,
	}

	json.NewEncoder(w).Encode(response)
}
