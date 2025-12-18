// Package authzserver implements Envoy's External Authorization gRPC API
// for validating GitHub OAuth tokens and enforcing authorization rules.
package authzserver

import (
	"context"
	"fmt"
	"log/slog"
	"strings"
	"sync"
	"time"

	corev3 "github.com/envoyproxy/go-control-plane/envoy/config/core/v3"
	authv3 "github.com/envoyproxy/go-control-plane/envoy/service/auth/v3"
	typev3 "github.com/envoyproxy/go-control-plane/envoy/type/v3"
	"google.golang.org/genproto/googleapis/rpc/status"
	"google.golang.org/grpc/codes"

	"github.com/agntcy/dir-staging/poc/github-authz/auth"
)

// AuthorizationServer implements the Envoy ext_authz gRPC API.
type AuthorizationServer struct {
	authv3.UnimplementedAuthorizationServer

	config *Config
	logger *slog.Logger

	// Cache for GitHub API responses
	userCache    map[string]*cachedUser
	userCacheMu  sync.RWMutex
	userCacheTTL time.Duration
}

// cachedUser stores cached GitHub user information.
type cachedUser struct {
	user      *auth.GitHubUser
	orgs      []string
	teams     map[string][]string // org -> teams
	expiresAt time.Time
}

// Config holds the authorization server configuration.
type Config struct {
	// OrganizationAllowList restricts access to users in these organizations.
	// Empty list means no organization restriction.
	OrganizationAllowList []string

	// TeamAllowList restricts access to users in specific teams within organizations.
	// Map of organization -> list of allowed teams.
	// If an org is in OrganizationAllowList but not in TeamAllowList, any team is allowed.
	TeamAllowList map[string][]string

	// UserAllowList explicitly allows specific users regardless of org/team membership.
	UserAllowList []string

	// UserDenyList explicitly denies specific users (takes precedence over allow lists).
	UserDenyList []string

	// CacheTTL is how long to cache GitHub API responses.
	CacheTTL time.Duration
}

// DefaultConfig returns a Config with sensible defaults.
func DefaultConfig() *Config {
	return &Config{
		OrganizationAllowList: []string{},
		TeamAllowList:         make(map[string][]string),
		UserAllowList:         []string{},
		UserDenyList:          []string{},
		CacheTTL:              5 * time.Minute,
	}
}

// NewAuthorizationServer creates a new authorization server.
func NewAuthorizationServer(config *Config, logger *slog.Logger) *AuthorizationServer {
	if config == nil {
		config = DefaultConfig()
	}
	if logger == nil {
		logger = slog.Default()
	}
	if config.CacheTTL == 0 {
		config.CacheTTL = 5 * time.Minute
	}

	return &AuthorizationServer{
		config:       config,
		logger:       logger,
		userCache:    make(map[string]*cachedUser),
		userCacheTTL: config.CacheTTL,
	}
}

// Check implements the ext_authz Check RPC.
func (s *AuthorizationServer) Check(ctx context.Context, req *authv3.CheckRequest) (*authv3.CheckResponse, error) {
	// Extract Authorization header
	httpReq := req.GetAttributes().GetRequest().GetHttp()
	authHeader := httpReq.GetHeaders()["authorization"]

	s.logger.Debug("received authorization request",
		"path", httpReq.GetPath(),
		"method", httpReq.GetMethod(),
		"has_auth_header", authHeader != "",
	)

	// Check if Authorization header exists
	if authHeader == "" {
		return s.denyResponse(codes.Unauthenticated, "missing Authorization header"), nil
	}

	// Parse Bearer token
	token, err := extractBearerToken(authHeader)
	if err != nil {
		return s.denyResponse(codes.Unauthenticated, err.Error()), nil
	}

	// Validate token and get user info
	user, orgs, err := s.validateTokenAndGetInfo(ctx, token)
	if err != nil {
		s.logger.Warn("token validation failed", "error", err)
		return s.denyResponse(codes.Unauthenticated, "invalid token: "+err.Error()), nil
	}

	// Check authorization rules
	if err := s.checkAuthorization(user.Login, orgs); err != nil {
		s.logger.Info("authorization denied",
			"user", user.Login,
			"orgs", orgs,
			"reason", err.Error(),
		)
		return s.denyResponse(codes.PermissionDenied, err.Error()), nil
	}

	s.logger.Info("authorization granted",
		"user", user.Login,
		"orgs", orgs,
	)

	return s.allowResponse(user, orgs), nil
}

// extractBearerToken extracts the token from a "Bearer <token>" header value.
func extractBearerToken(authHeader string) (string, error) {
	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 {
		return "", fmt.Errorf("invalid Authorization header format")
	}
	if !strings.EqualFold(parts[0], "bearer") {
		return "", fmt.Errorf("expected Bearer token, got %s", parts[0])
	}
	token := strings.TrimSpace(parts[1])
	if token == "" {
		return "", fmt.Errorf("empty token")
	}
	return token, nil
}

// validateTokenAndGetInfo validates the GitHub OAuth token and returns user information.
func (s *AuthorizationServer) validateTokenAndGetInfo(ctx context.Context, token string) (*auth.GitHubUser, []string, error) {
	// Check cache first
	s.userCacheMu.RLock()
	if cached, ok := s.userCache[token]; ok && time.Now().Before(cached.expiresAt) {
		s.userCacheMu.RUnlock()
		return cached.user, cached.orgs, nil
	}
	s.userCacheMu.RUnlock()

	// Validate token by calling GitHub API
	client := auth.NewGitHubClient(token)

	user, err := client.GetUser(ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to validate token: %w", err)
	}

	orgs, err := client.GetOrgNames(ctx)
	if err != nil {
		s.logger.Warn("failed to fetch organizations", "user", user.Login, "error", err)
		orgs = []string{} // Continue without org info
	}

	// Cache the result
	s.userCacheMu.Lock()
	s.userCache[token] = &cachedUser{
		user:      user,
		orgs:      orgs,
		expiresAt: time.Now().Add(s.userCacheTTL),
	}
	s.userCacheMu.Unlock()

	return user, orgs, nil
}

// checkAuthorization checks if the user is authorized based on the configured rules.
func (s *AuthorizationServer) checkAuthorization(username string, userOrgs []string) error {
	// Check deny list first (highest priority)
	for _, denied := range s.config.UserDenyList {
		if strings.EqualFold(username, denied) {
			return fmt.Errorf("user %q is in the deny list", username)
		}
	}

	// Check user allow list (explicit allow)
	for _, allowed := range s.config.UserAllowList {
		if strings.EqualFold(username, allowed) {
			return nil // Explicitly allowed
		}
	}

	// If no organization restrictions, allow all authenticated users
	if len(s.config.OrganizationAllowList) == 0 {
		return nil
	}

	// Check organization membership
	userOrgSet := make(map[string]bool)
	for _, org := range userOrgs {
		userOrgSet[strings.ToLower(org)] = true
	}

	for _, allowedOrg := range s.config.OrganizationAllowList {
		if userOrgSet[strings.ToLower(allowedOrg)] {
			// User is member of an allowed org
			// Check if team restrictions apply
			if teams, hasTeamRestriction := s.config.TeamAllowList[allowedOrg]; hasTeamRestriction {
				// TODO: Implement team membership check
				// For now, if team restriction exists but we haven't fetched teams, allow
				_ = teams
				s.logger.Debug("team restriction configured but not checked (not implemented)",
					"org", allowedOrg,
					"user", username,
				)
			}
			return nil // Allowed via org membership
		}
	}

	return fmt.Errorf("user %q is not a member of any allowed organization", username)
}

// allowResponse creates an OK response with user information headers.
func (s *AuthorizationServer) allowResponse(user *auth.GitHubUser, orgs []string) *authv3.CheckResponse {
	return &authv3.CheckResponse{
		Status: &status.Status{Code: int32(codes.OK)},
		HttpResponse: &authv3.CheckResponse_OkResponse{
			OkResponse: &authv3.OkHttpResponse{
				Headers: []*corev3.HeaderValueOption{
					{
						Header: &corev3.HeaderValue{
							Key:   "x-github-user",
							Value: user.Login,
						},
					},
					{
						Header: &corev3.HeaderValue{
							Key:   "x-github-user-id",
							Value: fmt.Sprintf("%d", user.ID),
						},
					},
					{
						Header: &corev3.HeaderValue{
							Key:   "x-github-orgs",
							Value: strings.Join(orgs, ","),
						},
					},
					{
						Header: &corev3.HeaderValue{
							Key:   "x-auth-method",
							Value: "github-oauth",
						},
					},
				},
			},
		},
	}
}

// denyResponse creates a denial response with the given code and message.
func (s *AuthorizationServer) denyResponse(code codes.Code, message string) *authv3.CheckResponse {
	httpStatus := typev3.StatusCode_Forbidden
	if code == codes.Unauthenticated {
		httpStatus = typev3.StatusCode_Unauthorized
	}

	return &authv3.CheckResponse{
		Status: &status.Status{
			Code:    int32(code),
			Message: message,
		},
		HttpResponse: &authv3.CheckResponse_DeniedResponse{
			DeniedResponse: &authv3.DeniedHttpResponse{
				Status: &typev3.HttpStatus{
					Code: httpStatus,
				},
				Body: fmt.Sprintf(`{"error": "%s", "message": "%s"}`, code.String(), message),
				Headers: []*corev3.HeaderValueOption{
					{
						Header: &corev3.HeaderValue{
							Key:   "content-type",
							Value: "application/json",
						},
					},
				},
			},
		},
	}
}

