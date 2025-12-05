# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Multi-architecture Docker image support (AMD64, ARM64, ARMv7)
- GitHub Actions workflow for automated multi-arch builds
- Comprehensive README with detailed documentation
- Health check configuration in Dockerfile and docker-compose.yaml
- `.env.example` file for easier configuration
- Resource limit examples in docker-compose.yaml
- Badges for Docker Hub and GitHub Actions in README
- Troubleshooting section in README
- Home Assistant integration examples
- Docker labels for better image metadata

### Changed
- **BREAKING**: Changed `EXPOSE 3002/udp` to `EXPOSE 3002/tcp` (correct protocol)
- Optimized Dockerfile using multi-stage build
  - Reduced image size by ~50%
  - Separated build and runtime dependencies
  - Improved layer caching
- Updated docker-compose.yaml to version 3.8
- Changed restart policy from `always` to `unless-stopped`
- Made config volume mount read-only for security
- Added default values for environment variables in docker-compose.yaml
- Enhanced configuration examples with more commands
- **Improved startup.sh script:**
  - Added `set -e` for fail-fast behavior
  - Better error handling and validation
  - Device existence check before permission changes
  - MQTT environment variable validation
  - Improved logging with clear status messages
  - Better process monitoring in both MQTT and non-MQTT modes
  - Graceful error messages in English
  - **Lock mechanism to prevent race conditions:**
    - Prevents simultaneous vclient access
    - Configurable timeout (default: 30s)
    - Exported functions for mqtt_sub.sh
    - Automatic stale lock cleanup
- **Improved config/mqtt_sub.sh script:**
  - Uses vclient_with_lock for safe concurrent access
  - Better error handling and logging
  - Command counter for tracking
  - Empty payload validation
  - Proper variable quoting
  - Cleaner result handling

### Fixed
- Removed unnecessary packages from runtime image (vim, ping, etc.)
- Proper cleanup of apt cache to reduce image size
- Missing executable permissions on startup.sh
- Inconsistent indentation in docker-compose.yaml
- Variable quoting issues in startup.sh
- Missing error handling in vclient calls
- No validation of required environment variables
- Daemon health check logic improved
- Multi-arch Docker build failures (corrected binary installation paths)
- Removed vsim binary copy (not needed for runtime, not always built)

### Security
- Config directory now mounted as read-only
- Removed privileged mode requirement
- Reduced attack surface by removing build tools from runtime image

## [1.0.0] - Previous Release

### Initial Features
- vcontrold daemon integration
- MQTT publishing support
- vclient for reading heating system values
- Docker containerization
- Basic configuration support
- Support for Viessmann Optolink interface

[Unreleased]: https://github.com/michelde/openv-vcontrold-docker/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/michelde/openv-vcontrold-docker/releases/tag/v1.0.0
