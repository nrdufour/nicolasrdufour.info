# --- Publishing -------------------------------------------------------------
# The site is served by `nemosites` (together with embryo-systems.info), a
# disposable NixOS box on Hetzner Cloud defined in the avalanche repo
# (docs/plans/nemosites.md). Publishing is a one-way push from here: that host
# holds no credential of its own, so nothing ever pulls from the homelab. The
# exact same recipe runs by hand and in CI (.forgejo/workflows/publish.yaml).

# Where to publish. Override before the DNS cutover, or to reach a rebuilt
# box before its records exist:  NRDUFOUR_HOST=203.0.113.10 just publish
host := env_var_or_default("NRDUFOUR_HOST", "www.nicolasrdufour.info")

# Private half of the dedicated publish key. A sops secret in avalanche
# (secrets/common-nicolasrdufour-publish), rendered by NixOS on calypso and on
# hawk's runner - it lives nowhere else, and the web host holds only the
# matching public key.
publish_key := env_var_or_default("NRDUFOUR_PUBLISH_KEY", "/run/secrets/nicolasrdufour/publish_ssh_key")

# Refuse to publish if it would delete more than this many files. A safety
# net against a broken build wiping the site, not a tuning knob - raise it
# inline for the rare publish that really does remove a lot. The built site
# is ~11 files, so anything near this is a wipe, not an edit.
max_delete := env_var_or_default("NRDUFOUR_MAX_DELETE", "5")

_default:
    @just --list --unsorted

# Hugo dev server with live reload, drafts included.
serve:
    hugo server -D

# Build the site into public/.
build:
    hugo --minify

# Regenerate favicon.ico and apple-touch-icon.png from favicon.svg, the source.
favicon:
    magick -background none -density 384 static/favicon.svg -define icon:auto-resize=48,32,16 static/favicon.ico
    magick -background none -density 384 static/favicon.svg -resize 180x180 static/apple-touch-icon.png

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
check: fmt-check lint build-check confusables script-check

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

# No inline <script> in the built site: scripts ship as files (script-src 'self').
script-check:
    #!/usr/bin/env bash
    set -euo pipefail
    out=$(mktemp -d)
    trap 'rm -rf "$out"' EXIT
    hugo --quiet --destination "$out"
    if hits=$(grep -rnoE '<script(>| [^>]*>)' "$out" --include='*.html' | grep -v 'src='); then
        echo "inline <script> in the built site:"
        echo "$hits"
        exit 1
    fi

# Build and push the site to the public web host.
publish:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -r "{{ publish_key }}" ]; then
      echo "ERROR: publish key not readable at {{ publish_key }}" >&2
      echo "       On calypso and hawk it is rendered there by sops-nix." >&2
      echo "       Elsewhere, point NRDUFOUR_PUBLISH_KEY at it." >&2
      exit 1
    fi
    out=$(mktemp -d)
    trap 'rm -rf "$out"' EXIT
    # Build to a temp dir, never ./public: a stale public/ from `hugo server`
    # would otherwise decide what the world sees.
    hugo --minify --destination "$out"

    # Normalise modes before sending. Two reasons this is not optional:
    # mktemp -d creates the directory 0700, and rsync -p would faithfully
    # reproduce that on the web root, leaving nginx unable to traverse into
    # it (403 on every page). And a build host with a restrictive umask would
    # otherwise publish unreadable files. rrsync's option allowlist rejects
    # --chmod, so the far side cannot fix this for us.
    chmod 755 "$out"
    find "$out" -type d -exec chmod 755 {} +
    find "$out" -type f -exec chmod 644 {} +

    # -rlptvc rather than -a. No -o/-g (the far side is rrsync, and everything
    # lands owned by the publish user regardless) and no -D (a static site has
    # no devices). -c is load-bearing: hugo rewrites every file on every build,
    # so the default size+mtime check would retransmit all of it every time.
    # --stats and --human-readable are deliberately absent - rrsync's option
    # allowlist rejects them and the transfer would die.
    #
    # The remote path is EMPTY, not "/": the forced command is
    # `rrsync -wo /var/www/nicolasrdufour`, and rrsync rejects a leading slash
    # as an unsafe arg. An empty path is the confined root.
    #
    # accept-new is trust-on-first-use, not blind trust: an unknown host is
    # recorded, but a host whose key has *changed* is a hard failure. The web
    # host generates its SSH key at first boot rather than baking it into the
    # snapshot, so after `just cloud destroy` + `create` its key is genuinely
    # new - drop the stale known_hosts line then, and only then.
    ssh_cmd="ssh -i {{ publish_key }} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

    # Pre-flight: count what --delete would remove, and refuse BEFORE sending
    # anything. A dry run is the only form of this check that leaves the site
    # untouched when it trips (--max-delete would let the first N deletions
    # through and leave the site mangled).
    doomed=$(rsync -rlptcn --delete -v -e "$ssh_cmd" \
      "$out/" "publish-nrd@{{ host }}:" | grep -c '^deleting ' || true)

    if [ "$doomed" -gt {{ max_delete }} ]; then
      echo >&2
      echo "ERROR: this publish would delete $doomed files. Refusing." >&2
      echo "       Nothing was sent; the live site is untouched." >&2
      echo "       A build this much smaller than what is deployed usually" >&2
      echo "       means an empty content/, the wrong branch, or a broken" >&2
      echo "       config rather than a genuine deletion." >&2
      echo "       If the deletion really is intended, re-run with:" >&2
      echo "         NRDUFOUR_MAX_DELETE=$((doomed + 1)) just publish" >&2
      exit 1
    fi
    [ "$doomed" -gt 0 ] && echo "==> will remove $doomed stale file(s)" || true

    rsync -rlptvc --delete -e "$ssh_cmd" "$out/" "publish-nrd@{{ host }}:"

    echo "published to {{ host }}"
