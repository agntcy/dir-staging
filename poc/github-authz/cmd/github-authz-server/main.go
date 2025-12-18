// Package main provides the GitHub Authorization Server for Envoy ext_authz.
//
// This server implements Envoy's External Authorization gRPC API to validate
// GitHub OAuth tokens and enforce authorization rules based on organization,
// team, and user membership.
//
// Usage:
//
//	# Start the server with default configuration
//	go run ./cmd/github-authz-server
//
//	# With environment variables
//	GITHUB_ALLOWED_ORGS=agntcy,spiffe AUTHZ_PORT=9001 go run ./cmd/github-authz-server
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	authv3 "github.com/envoyproxy/go-control-plane/envoy/service/auth/v3"
	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	"google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/reflection"

	"github.com/agntcy/dir-staging/poc/github-authz/authzserver"
)

const (
	defaultPort     = "9001"
	defaultCacheTTL = 5 * time.Minute
)

func main() {
	// Setup structured logging
	logLevel := slog.LevelInfo
	if os.Getenv("DEBUG") == "true" {
		logLevel = slog.LevelDebug
	}
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: logLevel,
	}))
	slog.SetDefault(logger)

	// Load configuration
	config, err := loadConfig()
	if err != nil {
		logger.Error("failed to load configuration", "error", err)
		os.Exit(1)
	}

	// Log configuration (without sensitive data)
	logger.Info("starting GitHub Authorization Server",
		"port", getEnv("AUTHZ_PORT", defaultPort),
		"allowed_orgs", config.OrganizationAllowList,
		"allowed_users_count", len(config.UserAllowList),
		"denied_users_count", len(config.UserDenyList),
		"cache_ttl", config.CacheTTL,
	)

	// Create authorization server
	authzServer := authzserver.NewAuthorizationServer(config, logger)

	// Create gRPC server
	grpcServer := grpc.NewServer(
		grpc.ChainUnaryInterceptor(
			loggingInterceptor(logger),
		),
	)

	// Register services
	authv3.RegisterAuthorizationServer(grpcServer, authzServer)

	// Register health check service
	healthServer := health.NewServer()
	grpc_health_v1.RegisterHealthServer(grpcServer, healthServer)
	healthServer.SetServingStatus("", grpc_health_v1.HealthCheckResponse_SERVING)

	// Enable reflection for debugging
	reflection.Register(grpcServer)

	// Start listening
	port := getEnv("AUTHZ_PORT", defaultPort)
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		logger.Error("failed to listen", "port", port, "error", err)
		os.Exit(1)
	}

	// Handle graceful shutdown
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	// Start server in goroutine
	go func() {
		logger.Info("server listening", "address", listener.Addr().String())
		if err := grpcServer.Serve(listener); err != nil {
			logger.Error("server error", "error", err)
		}
	}()

	// Wait for shutdown signal
	<-ctx.Done()
	logger.Info("shutting down server...")

	// Graceful shutdown
	healthServer.SetServingStatus("", grpc_health_v1.HealthCheckResponse_NOT_SERVING)
	grpcServer.GracefulStop()
	logger.Info("server stopped")
}

// loadConfig loads configuration from environment variables.
func loadConfig() (*authzserver.Config, error) {
	config := authzserver.DefaultConfig()

	// Organization allow list
	if orgs := os.Getenv("GITHUB_ALLOWED_ORGS"); orgs != "" {
		config.OrganizationAllowList = splitAndTrim(orgs, ",")
	}

	// User allow list
	if users := os.Getenv("GITHUB_ALLOWED_USERS"); users != "" {
		config.UserAllowList = splitAndTrim(users, ",")
	}

	// User deny list
	if users := os.Getenv("GITHUB_DENIED_USERS"); users != "" {
		config.UserDenyList = splitAndTrim(users, ",")
	}

	// Team allow list (JSON format: {"org": ["team1", "team2"]})
	if teamsJSON := os.Getenv("GITHUB_ALLOWED_TEAMS"); teamsJSON != "" {
		var teams map[string][]string
		if err := json.Unmarshal([]byte(teamsJSON), &teams); err != nil {
			return nil, fmt.Errorf("invalid GITHUB_ALLOWED_TEAMS JSON: %w", err)
		}
		config.TeamAllowList = teams
	}

	// Cache TTL
	if ttl := os.Getenv("AUTHZ_CACHE_TTL"); ttl != "" {
		duration, err := time.ParseDuration(ttl)
		if err != nil {
			return nil, fmt.Errorf("invalid AUTHZ_CACHE_TTL: %w", err)
		}
		config.CacheTTL = duration
	}

	return config, nil
}

// splitAndTrim splits a string and trims whitespace from each part.
func splitAndTrim(s, sep string) []string {
	parts := strings.Split(s, sep)
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

// getEnv returns the value of an environment variable or a default value.
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// loggingInterceptor creates a gRPC unary interceptor for logging.
func loggingInterceptor(logger *slog.Logger) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req interface{},
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (interface{}, error) {
		start := time.Now()
		resp, err := handler(ctx, req)
		duration := time.Since(start)

		logger.Debug("gRPC request",
			"method", info.FullMethod,
			"duration_ms", duration.Milliseconds(),
			"error", err,
		)

		return resp, err
	}
}

