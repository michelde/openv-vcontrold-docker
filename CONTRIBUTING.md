# Contributing to openv-vcontrold-docker

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Bug Report Template:**
```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Start container with '...'
2. Execute command '...'
3. See error

**Expected behavior**
What you expected to happen.

**Environment:**
- OS: [e.g., Ubuntu 22.04, Synology DSM 7.2]
- Docker version: [e.g., 24.0.5]
- Architecture: [e.g., amd64, arm64, armv7]
- Heating system: [e.g., Vitocal 200-S]

**Configuration:**
- vcontrold.xml: [relevant sections]
- Environment variables used
- Device mapping

**Logs:**
```
Paste relevant log output here
```

**Additional context**
Any other information about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- Clear and descriptive title
- Detailed description of the proposed functionality
- Explanation of why this enhancement would be useful
- Example use cases

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following the coding standards below
3. **Test your changes** thoroughly
4. **Update documentation** if needed
5. **Write a clear commit message**
6. **Submit a pull request**

#### Pull Request Process

1. Update the README.md with details of changes if applicable
2. Update the CHANGELOG.md under [Unreleased] section
3. Ensure the Docker image builds successfully
4. Test on multiple architectures if possible
5. Request review from maintainers

## Development Guidelines

### Dockerfile Best Practices

- Use multi-stage builds to minimize image size
- Combine RUN commands where appropriate to reduce layers
- Clean up package manager caches
- Use specific versions for base images when stability is critical
- Add meaningful labels
- Include health checks
- Don't run containers as root when possible

### Shell Script Guidelines

- Use `#!/bin/bash` shebang
- Include comments for complex logic
- Use meaningful variable names
- Handle errors appropriately
- Quote variables to prevent word splitting
- Use `set -e` for critical scripts

### Docker Compose

- Use version 3.8 or higher
- Include comments for configuration options
- Provide sensible defaults
- Document all environment variables
- Use health checks
- Include resource limits where appropriate

### Documentation

- Keep README.md up to date
- Use clear, concise language
- Include code examples where helpful
- Update CHANGELOG.md for all changes
- Document breaking changes clearly

## Testing

### Local Testing

```bash
# Build the image locally
docker build -t vcontrold-test .

# Run the container
docker run -d \
  --name vcontrold-test \
  --device=/dev/ttyUSB0:/dev/vitocal \
  -e MQTTACTIVE=false \
  vcontrold-test

# Check logs
docker logs -f vcontrold-test

# Test vclient
docker exec vcontrold-test vclient -h 127.0.0.1 -p 3002 -c getTempA

# Clean up
docker stop vcontrold-test
docker rm vcontrold-test
```

### Multi-Architecture Testing

```bash
# Set up buildx
docker buildx create --name multiarch --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t vcontrold-test:multiarch \
  --load .
```

### Testing with MQTT

1. Set up a test MQTT broker (e.g., Eclipse Mosquitto)
2. Configure environment variables
3. Verify messages are published correctly
4. Test command subscription functionality

## Project Structure

```
openv-vcontrold-docker/
├── .github/
│   └── workflows/
│       └── docker-build.yml    # CI/CD pipeline
├── config/                      # Configuration files
│   ├── mqtt_publish.sh
│   ├── mqtt_sub.sh
│   ├── vcontrold.xml
│   └── vito.xml
├── .env.example                 # Environment variable template
├── .gitignore
├── CHANGELOG.md                 # Change history
├── CONTRIBUTING.md              # This file
├── docker-compose.yaml          # Docker Compose configuration
├── Dockerfile                   # Docker image definition
├── LICENSE                      # Project license
├── README.md                    # Main documentation
└── startup.sh                   # Container entrypoint script
```

## Commit Message Guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Build system changes
- `ci`: CI/CD changes
- `chore`: Other changes (dependencies, etc.)

**Examples:**
```
feat: add support for TLS MQTT connections
fix: correct device permission handling
docs: update README with Synology instructions
ci: add multi-arch build workflow
```

## Release Process

1. Update version in relevant files
2. Update CHANGELOG.md with release date
3. Create a git tag: `git tag -a v1.0.0 -m "Release 1.0.0"`
4. Push tag: `git push origin v1.0.0`
5. GitHub Actions will automatically build and publish

## Questions?

If you have questions about contributing:
- Open an issue with the `question` label
- Start a discussion in GitHub Discussions
- Check existing documentation

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

Thank you for contributing! 🎉
