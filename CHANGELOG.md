# Changelog

## v0.5.5 (2025-12-03)

### Updated
- Bump DIR components to v0.5.5 (from v0.5.2)
- Enable SPIFFE CSI driver for reliable identity injection (`useCSIDriver: true`)
- Add OASF API validation configuration (lax mode by default)

### Added
- SPIFFE CSI driver configuration for dir-apiserver and dir-admin
  - Eliminates "certificate contains no URI SAN" authentication failures
  - Provides synchronous workload registration (no race conditions)
- OASF validation lax mode (`oasf_api_validation_strict_mode: false`)
  - Allows validation warnings for non-standard OASF modules
  - Rejects actual validation errors

### Changed
- SPIRE integration now uses CSI ephemeral volumes instead of hostPath
  - More secure (avoids hostPath in workload containers)
  - More reliable (synchronous identity injection)

---

## v0.5.2 (2025-11-24)

### Updated
- Bump DIR components to v0.5.2 (from v0.4.0)
- Modernize configuration with production deployment patterns
- Add resource limits for Kind-friendly deployment
- Apply Pod Security Standards
- Add rate limiting configuration
- Update trust domain to `example.org`

### Added
- SQLite PVC configuration support for persistent database storage
- Deployment strategy configuration (Recreate) to prevent lock conflicts
- Automatic `/tmp` emptyDir mounting when `readOnlyRootFilesystem` is enabled
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
- Database PVC persistence guide for production
- Deployment strategy requirements for PVC usage
- ExternalSecrets pattern documentation
- Production deployment considerations

---

## 0.0.1 (2025-02-04)

### Feat

- Add commitizen
- Initial Commit to create the scaffolding to template repo and relevant github actions
