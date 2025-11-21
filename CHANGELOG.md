# Changelog

## v0.5.2 (2025-11-20)

### Updated
- Bump DIR components to v0.5.2 (from v0.4.0)
- Modernize configuration with production deployment patterns
- Add resource limits for Kind-friendly deployment
- Apply Pod Security Standards
- Add rate limiting configuration
- Update trust domain to `example.org`

### Added
- Resource limits (DIR: 250m/512Mi requests, Zot: 100m/256Mi requests)
- Pod Security Standards (seccomp, runAsNonRoot, drop capabilities)
- Rate limiting (50 RPS for local Kind)
- Documentation for optional production features

### Security
- seccompProfile (RuntimeDefault)
- Enforce non-root execution
- Drop all container capabilities
- Explicit user ID (65532)

### Documentation
- Optional PVC persistence guide
- ExternalSecrets pattern documentation
- Production deployment considerations

---

## 0.0.1 (2025-02-04)

### Feat

- Add commitizen
- Initial Commit to create the scaffolding to template repo and relevant github actions
