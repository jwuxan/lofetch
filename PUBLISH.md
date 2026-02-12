# Publishing Guide

This document describes how to publish new versions of lofetch to npm and update the Homebrew formula.

## Prerequisites

- npm account with publish access to the `lofetch` package
- GitHub repository with release tags
- Git repository with clean working tree

## Publishing Checklist

### 1. Update Version

Update the version in these files:

- `package.json` - npm version
- `lofetch` - `LOFETCH_VERSION` constant (line 12)
- `Formula/lofetch.rb` - version and URL
- `CHANGELOG.md` - add release notes

### 2. Run Tests

```bash
# Run all tests
make test
bash test_package.sh

# Lint
make lint
```

All tests must pass before publishing.

### 3. Commit and Tag

```bash
# Commit version bump
git add package.json lofetch Formula/lofetch.rb CHANGELOG.md
git commit -m "chore: bump version to X.Y.Z"

# Create git tag
git tag -a vX.Y.Z -m "Release vX.Y.Z"

# Push commits and tags
git push origin main
git push origin vX.Y.Z
```

### 4. Create GitHub Release

1. Go to https://github.com/jwuxan/lofetch/releases/new
2. Select the tag you just created (vX.Y.Z)
3. Title: `vX.Y.Z`
4. Description: Copy relevant sections from CHANGELOG.md
5. Click "Publish release"

### 5. Update Homebrew Formula SHA256

After creating the GitHub release:

```bash
# Download the release tarball
curl -L https://github.com/jwuxan/lofetch/archive/refs/tags/vX.Y.Z.tar.gz -o release.tar.gz

# Calculate SHA256
shasum -a 256 release.tar.gz

# Update Formula/lofetch.rb with the SHA256
# Replace the empty sha256 "" with the calculated hash
```

### 6. Publish to npm

```bash
# Dry run to see what will be published
npm pack
tar -tzf lofetch-X.Y.Z.tgz

# Login to npm (if not already logged in)
npm login

# Publish to npm
npm publish

# Verify it's published
npm view lofetch
```

### 7. Test Installation

Test both installation methods:

```bash
# Test npm installation
npm install -g lofetch
lofetch --version
npm uninstall -g lofetch

# Test npx
npx lofetch@X.Y.Z

# Test Homebrew (requires creating a tap or PR to homebrew-core)
brew tap jwuxan/lofetch https://github.com/jwuxan/lofetch
brew install lofetch
lofetch --version
brew uninstall lofetch
```

## Homebrew Tap Setup

To create a Homebrew tap for easy installation:

```bash
# The repository becomes the tap automatically
# Users can install with:
brew tap jwuxan/lofetch https://github.com/jwuxan/lofetch
brew install lofetch
```

## Submitting to homebrew-core (Optional)

For wider distribution, you can submit lofetch to the official homebrew-core repository:

1. Fork https://github.com/Homebrew/homebrew-core
2. Add `Formula/lofetch.rb` to your fork
3. Test the formula: `brew install --build-from-source ./Formula/lofetch.rb`
4. Submit a pull request to homebrew-core
5. Follow the review process

Note: homebrew-core has strict requirements. See https://github.com/Homebrew/brew/blob/master/docs/Acceptable-Formulae.md

## Troubleshooting

### npm publish fails with 403

```bash
# Check you're logged in
npm whoami

# Check package name availability
npm view lofetch

# If the package name is taken, use a scoped package:
# Update package.json name to "@your-username/lofetch"
```

### Homebrew formula fails to install

```bash
# Test the formula locally
brew install --build-from-source --verbose ./Formula/lofetch.rb

# Audit the formula
brew audit --strict Formula/lofetch.rb
```

### Wrong version after install

Clear npm and Homebrew caches:

```bash
npm cache clean --force
brew cleanup
brew update
```

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes, incompatible API changes
- **MINOR** (X.Y.0): New features, backward-compatible
- **PATCH** (X.Y.Z): Bug fixes, backward-compatible

## Rollback

If you need to unpublish a version:

```bash
# Unpublish a specific version (within 72 hours)
npm unpublish lofetch@X.Y.Z

# Deprecate a version (after 72 hours)
npm deprecate lofetch@X.Y.Z "Reason for deprecation"
```

For Homebrew, submit a PR reverting the formula changes.
