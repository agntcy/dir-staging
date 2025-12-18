package auth

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
)

const (
	// GitHubAPIURL is the base URL for GitHub's API.
	GitHubAPIURL = "https://api.github.com"
)

// GitHubUser represents a GitHub user.
type GitHubUser struct {
	Login     string `json:"login"`
	ID        int64  `json:"id"`
	Name      string `json:"name"`
	Email     string `json:"email"`
	AvatarURL string `json:"avatar_url"`
}

// GitHubOrg represents a GitHub organization.
type GitHubOrg struct {
	Login       string `json:"login"`
	ID          int64  `json:"id"`
	Description string `json:"description"`
}

// GitHubClient is a client for GitHub's API.
type GitHubClient struct {
	accessToken string
	httpClient  *http.Client
}

// NewGitHubClient creates a new GitHub API client.
func NewGitHubClient(accessToken string) *GitHubClient {
	return &GitHubClient{
		accessToken: accessToken,
		httpClient:  &http.Client{},
	}
}

// GetUser fetches the authenticated user's information.
func (c *GitHubClient) GetUser(ctx context.Context) (*GitHubUser, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", GitHubAPIURL+"/user", nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+c.accessToken)
	req.Header.Set("Accept", "application/vnd.github.v3+json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch user: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GitHub API error: %s", resp.Status)
	}

	var user GitHubUser
	if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
		return nil, fmt.Errorf("failed to parse user response: %w", err)
	}

	return &user, nil
}

// GetOrgs fetches the authenticated user's organizations.
func (c *GitHubClient) GetOrgs(ctx context.Context) ([]GitHubOrg, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", GitHubAPIURL+"/user/orgs", nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+c.accessToken)
	req.Header.Set("Accept", "application/vnd.github.v3+json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch orgs: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GitHub API error: %s", resp.Status)
	}

	var orgs []GitHubOrg
	if err := json.NewDecoder(resp.Body).Decode(&orgs); err != nil {
		return nil, fmt.Errorf("failed to parse orgs response: %w", err)
	}

	return orgs, nil
}

// IsMemberOfOrg checks if the authenticated user is a member of the specified organization.
func (c *GitHubClient) IsMemberOfOrg(ctx context.Context, org string) (bool, error) {
	orgs, err := c.GetOrgs(ctx)
	if err != nil {
		return false, err
	}

	for _, o := range orgs {
		if o.Login == org {
			return true, nil
		}
	}

	return false, nil
}

// IsMemberOfAnyOrg checks if the authenticated user is a member of any of the specified organizations.
func (c *GitHubClient) IsMemberOfAnyOrg(ctx context.Context, allowedOrgs []string) (bool, string, error) {
	orgs, err := c.GetOrgs(ctx)
	if err != nil {
		return false, "", err
	}

	orgMap := make(map[string]bool)
	for _, o := range orgs {
		orgMap[o.Login] = true
	}

	for _, allowed := range allowedOrgs {
		if orgMap[allowed] {
			return true, allowed, nil
		}
	}

	return false, "", nil
}

// GetOrgNames returns the names of the user's organizations.
func (c *GitHubClient) GetOrgNames(ctx context.Context) ([]string, error) {
	orgs, err := c.GetOrgs(ctx)
	if err != nil {
		return nil, err
	}

	names := make([]string, len(orgs))
	for i, org := range orgs {
		names[i] = org.Login
	}

	return names, nil
}

