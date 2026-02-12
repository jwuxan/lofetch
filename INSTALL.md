# Installation

lofetch can be installed via npm, Homebrew, or manual installation.

## npm

### Global installation

Install globally to use `lofetch` command anywhere:

```bash
npm install -g lofetch
```

### Run without installing (npx)

Run directly without installation:

```bash
npx lofetch
```

### Uninstall

```bash
npm uninstall -g lofetch
```

## Homebrew

### Install from this tap

```bash
brew tap jwuxan/lofetch https://github.com/jwuxan/lofetch
brew install lofetch
```

### Install from local Formula

If you've cloned this repository:

```bash
brew install --build-from-source ./Formula/lofetch.rb
```

### Uninstall

```bash
brew uninstall lofetch
```

## Manual Installation

### macOS / Linux

```bash
# Download the script
curl -O https://raw.githubusercontent.com/jwuxan/lofetch/main/lofetch

# Make it executable
chmod +x lofetch

# Move to your PATH (optional)
sudo mv lofetch /usr/local/bin/

# Or keep it local
mkdir -p ~/.local/bin
mv lofetch ~/.local/bin/
# Add ~/.local/bin to your PATH if not already
```

### Windows (WSL / Git Bash / MINGW)

```bash
# Download the script
curl -O https://raw.githubusercontent.com/jwuxan/lofetch/main/lofetch

# Make it executable
chmod +x lofetch

# Move to your PATH
mv lofetch /usr/local/bin/
# Or use: mv lofetch ~/bin/
```

## Verify Installation

After installation, verify it works:

```bash
lofetch
lofetch --version
lofetch --help
```

## Updating

### npm

```bash
npm update -g lofetch
```

### Homebrew

```bash
brew upgrade lofetch
```

### Manual

Re-download and replace the script following the manual installation steps above.

## Requirements

- Bash 4.0+ (Bash 3.2+ supported with limited features)
- No other dependencies required — completely self-contained!

## Troubleshooting

### Command not found after npm install

Ensure npm's global bin directory is in your PATH:

```bash
npm config get prefix  # Should show a directory in your PATH
echo $PATH | grep "$(npm config get prefix)"
```

If not, add it to your shell profile (~/.bashrc, ~/.zshrc):

```bash
export PATH="$(npm config get prefix)/bin:$PATH"
```

### Permission denied

If you get permission errors during npm global install:

```bash
# Option 1: Use npx instead (no installation needed)
npx lofetch

# Option 2: Fix npm permissions (one-time setup)
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH  # Add to your shell profile
```

### Script not executable

```bash
chmod +x $(which lofetch)
```
