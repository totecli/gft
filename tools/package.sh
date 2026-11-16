#!/usr/bin/env bash
# Build the release archive of the gft plugin and its checksum.
#
#   tools/package.sh
#
# Writes dist/plugin-gft.tar.gz and dist/plugin-gft.tar.gz.sha256 (the line that "sha256sum -c"
# reads) and prints the sha256 of the archive. The names are the ones that scripts/vendor.sh of tote
# and the install commands of the README expect.
#
# The archive holds the package at its root, with no folder around it, and only what a declarative
# plugin may ship (docs/plugins/API1.md, section 2.1): plugin.toml, locales/ and LICENSE. The README
# and the tooling of this repository stay out of it, so that a change of the documentation never
# changes the hash of the package.
#
# The archive is reproducible: sorted names, owner 0, fixed times and modes, and a gzip header with
# no name and no time. Two runs on any machine with GNU tar give the same bytes. The script builds
# it twice and compares.
#
# Environment:
#   TOTE_BIN   a tote binary with the "plugin check" verb (1.1.0 or later). When set, the archive is
#              checked with --strict --official before the script says it is done. (The repository
#              itself is not a package: check refuses a folder that holds tools/ or dist/.)
#   TAR        GNU tar (default: tar; "gtar" on macOS)
set -euo pipefail

readonly name="plugin-gft"
readonly mtime="2026-01-01 00:00Z"
readonly files=(LICENSE locales plugin.toml)

die() { printf 'package: %s\n' "$*" >&2; exit 1; }

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

tar_bin=${TAR:-tar}
command -v "$tar_bin" >/dev/null 2>&1 || die "$tar_bin is required"
"$tar_bin" --version 2>/dev/null | grep -q 'GNU tar' || die "GNU tar is required (set TAR=gtar on macOS)"
command -v gzip >/dev/null 2>&1 || die "gzip is required"

if command -v sha256sum >/dev/null 2>&1; then
    sha256() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
    sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
else
    die "sha256sum or shasum is required"
fi

for f in "${files[@]}"; do
    [ -e "$f" ] || die "missing $f: run the script from a checkout of the repository"
done
[ -f locales/en.toml ] && [ -f locales/fr.toml ] || die "locales/en.toml and locales/fr.toml are required"

# The tag of a release equals the version of the manifest, without "v" (tote refuses anything else).
version=$(sed -n 's/^version = "\([^"]*\)"$/\1/p' plugin.toml | head -n 1)
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$ ]] || die "no valid version in plugin.toml: '$version'"
if [ -n "${GITHUB_REF_NAME:-}" ] && [ "${GITHUB_REF_TYPE:-}" = "tag" ] && [ "$GITHUB_REF_NAME" != "$version" ]; then
    die "the tag $GITHUB_REF_NAME is not the version $version of plugin.toml"
fi

# Build to $1.
build() {
    "$tar_bin" --sort=name --owner=0 --group=0 --numeric-owner --mtime="$mtime" \
        --mode='u=rwX,go=rX' --format=gnu -cf - "${files[@]}" | gzip -n -9 >"$1"
}

mkdir -p dist
archive="dist/$name.tar.gz"
again="dist/$name.tar.gz.again"

build "$archive"
build "$again"
first=$(sha256 "$archive")
second=$(sha256 "$again")
rm -f -- "$again"
[ "$first" = "$second" ] || die "the archive is not reproducible: $first and $second"

# What is inside, before anyone reads it: no folder around the package, nothing else.
listing=$("$tar_bin" -tzf "$archive" | LC_ALL=C sort | tr '\n' ' ')
want="LICENSE locales/ locales/en.toml locales/fr.toml plugin.toml "
[ "$listing" = "$want" ] || die "unexpected content of the archive: $listing"

printf '%s  %s\n' "$first" "$name.tar.gz" >"$archive.sha256"
(cd dist && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c "$name.tar.gz.sha256"; else shasum -a 256 -c "$name.tar.gz.sha256"; fi >/dev/null) \
    || die "the checksum file does not match the archive"

if [ -n "${TOTE_BIN:-}" ]; then
    command -v "$TOTE_BIN" >/dev/null 2>&1 || die "TOTE_BIN is not an executable: $TOTE_BIN"
    # "./" makes tote read the argument as a path and not as the id of a plugin.
    "$TOTE_BIN" plugin check "./$archive" --strict --official >/dev/null \
        || die "tote plugin check ./$archive failed (run it to see why)"
fi

printf 'plugin gft %s\n' "$version"
printf 'archive: %s\n' "$archive"
printf 'sha256:  %s\n' "$first"
