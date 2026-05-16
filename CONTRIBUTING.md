# Contributing to SSH Brute-Force Detection Grid

Thank you for your interest in contributing!

## How to Contribute

### Reporting Bugs

1. Check existing issues before creating a new one
2. Use the bug report template
3. Include:
   - Clear bug description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details

### Suggesting Features

1. Check existing issues and pull requests
2. Use the feature request template
3. Explain the motivation and use case

### Pull Requests

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Make your changes
4. Run tests and linting:
   ```bash
   # Run tests
   python tests/test_detection.py

   # Run linting
   flake8 tests/
   yamllint .
   ```
5. Commit with clear messages:
   ```bash
   git commit -m "Add: Detect slow brute force attacks"
   ```
6. Push and create a PR

## Code Style

- Python: Follow PEP 8
- Bash: ShellCheck compliance
- YAML: yamllint compliance
- Splunk: Follow best practices

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ssh-brute-force-detection.git
cd ssh-brute-force-detection

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run tests
python tests/test_detection.py
```

## Security Considerations

- Never commit credentials or secrets
- Use environment variables for sensitive data
- Test only on systems you own/have permission to test
- Follow responsible disclosure for security issues

## Questions?

- Open a GitHub Discussion
- Check existing documentation in `/docs`

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
