# Contributing

Thank you for improving HyprSequoia. Open an issue for significant behavior or
visual changes before implementation. Keep modules focused, avoid optional AUR
dependencies unless they provide unique value, and never import configuration
from another dotfiles repository.

## Development checks

```bash
shellcheck install.sh update.sh restore.sh uninstall-kde.sh scripts/lib/*.sh scripts/bin/*
find . -name '*.json' -print0 | xargs -0 -n1 jq empty
```

Test installation in a clean Arch virtual machine. Verify first install,
repeated install, induced deployment failure, restore, and a session launched by
SDDM. Pull requests should update documentation and `CHANGELOG.md` when behavior
changes. Use Conventional Commit-style concise subjects where practical.

Configuration comments should explain intent, not restate syntax. Shell
functions require a short documentation comment; quote expansions and preserve
strict mode. New dependencies must be documented with repository origin and
purpose.
