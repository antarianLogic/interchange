# Contributing to Interchange

If you have interest in contributing to Interchange, thank you! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and considerate in all interactions
- Welcome newcomers and help them get started
- Focus on constructive feedback
- Respect differing viewpoints and experiences

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. Check if the issue already exists in the GitHub Issues
2. If not, create a new issue with:
   - A clear, descriptive title
   - Detailed description of the problem or feature
   - Steps to reproduce (for bugs)
   - Expected vs. actual behavior
   - Your environment (Swift version, platform, Xcode version)
   - Code samples if applicable
3. If it's a major feature request, or you are not 100% sure it's a bug, wait for confirmation from project leaders before creating a pull request

### Submitting Pull Requests

1. **Fork the repository** and create a new branch:
   ```bash
   git checkout -b feature/my-new-feature
   ```
   or
   ```bash
   git checkout -b fix/issue-123
   ```

2. **Make your changes**:
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed
   - Ensure all tests pass

3. **Commit your changes**:
   - Use clear, descriptive commit messages
   - Reference issues when applicable (e.g., "Fixes #123")

4. **Push to your fork**:
   ```bash
   git push origin feature/my-new-feature
   ```

5. **Create a Pull Request**:
   - Provide a clear description of the changes
   - Link to any related issues
   - Explain why the change is needed

## Development Guidelines

### General

- Confirm all added API meant to be externally visible is marked `public`
- Test with an external project to verify all added API is visible, builds, and works
 
### Testing

- Write tests for new features and bug fixes
- Ensure all tests pass before submitting a PR
- Use Swift Testing framework (`@Test`, `#expect`, etc.)
- Use the `Mocker` testing framework if necessary

### Code Style

- Follow Swift API Design Guidelines
- Use descriptive variable and function names
- Add documentation comments for public APIs
- Ensure all public types and methods are documented
- Try to follow existing formatting style

### Documentation

- Update inline documentation (DocC comments)
- Update Xcode Documentation Catalog if appropriate
- Add code examples for new features

## Areas for Contribution

We welcome contributions in these areas:

### Features
- Additional HTTP authentication methods
- Enhanced error recovery mechanisms
- More caching strategies
- WebSocket support
- GraphQL support

### Documentation
- More code examples
- Tutorial articles
- API reference improvements
- Translation to other languages

### Testing
- Additional unit tests
- Integration tests
- Performance tests
- Mock implementations

### Code Quality
- Performance optimizations
- Code refactoring
- Better error messages
- Improved logging

## Questions?

If you have questions about contributing:

1. Check existing documentation and issues
2. Ask in a GitHub Discussion
3. Open an issue with the "question" label

## Recognition

Contributors will be acknowledged in:
- The project README
- Release notes
- GitHub contributors page

## License

By contributing to Interchange, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Interchange! 🎉
