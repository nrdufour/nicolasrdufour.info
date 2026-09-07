_default:
    @just --list --unsorted

# Hugo dev server with live reload, drafts included.
serve:
    hugo server -D

# Build the site into public/.
build:
    hugo --minify

# statix and deadnix over every tracked Nix file.
lint:
    statix check .
    deadnix --fail $(git ls-files '*.nix')

# Format every tracked Nix file in place.
fmt:
    nixfmt $(git ls-files '*.nix')

# Fail if any tracked Nix file needs formatting.
fmt-check:
    nixfmt --check $(git ls-files '*.nix')

# Build into a throwaway directory so the check never leaves a public/ behind.
build-check:
    #!/usr/bin/env bash
    set -euo pipefail
    out=$(mktemp -d)
    trap 'rm -rf "$out"' EXIT
    hugo --minify --panicOnWarning --destination "$out"

# What CI runs, so a red build is reproducible in one command.
check: fmt-check lint build-check confusables

# Characters that render like ASCII, or render as nothing at all, but compare
# unequal. CI runs this in its own workflow, without a path filter, so it
# covers prose too.

# Grep for characters confusable with ASCII, or invisible.
confusables:
    #!/usr/bin/env bash
    pattern='[\x{2010}-\x{2015}\x{2212}\x{2018}\x{2019}\x{201A}\x{201C}\x{201D}\x{201E}\x{2032}\x{2033}\x{00B7}\x{2026}\x{00D7}\x{00A0}\x{200B}-\x{200D}\x{2060}\x{FEFF}]'
    if hits=$(git ls-files | xargs grep -nIP "$pattern" 2>/dev/null); then
        echo "characters confusable with ASCII, or invisible:"
        echo "$hits"
        echo
        echo "Use - . ... x and a plain space instead."
        exit 1
    fi
