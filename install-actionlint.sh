#!/usr/bin/env bash
set -euo pipefail

ACTIONLINT_VERSION=1.7.12

if command -v actionlint >/dev/null 2>&1 &&
  [ "$(actionlint --version | head -n1)" = "$ACTIONLINT_VERSION" ]; then
  echo "actionlint ${ACTIONLINT_VERSION} already installed" >&2
  exit 0
fi

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "$arch" in
x86_64) arch=amd64 ;;
aarch64 | arm64) arch=arm64 ;;
*)
  echo "install-actionlint.sh: unsupported architecture: $arch" >&2
  exit 1
  ;;
esac

archive="actionlint_${ACTIONLINT_VERSION}_${os}_${arch}.tar.gz"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  # preferred: trusted download, verified against GitHub's build attestation
  gh release download "v${ACTIONLINT_VERSION}" --repo rhysd/actionlint --pattern "$archive"
  gh attestation verify -R rhysd/actionlint "$archive"
else
  # fallback: plain download, verified against the published checksums
  echo "install-actionlint.sh cannot use gh fallback to plain download" >&2
  base_url="https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}"
  curl -sSLO "${base_url}/${archive}"
  curl -sSLO "${base_url}/actionlint_${ACTIONLINT_VERSION}_checksums.txt"
  sha256sum --ignore-missing --check "actionlint_${ACTIONLINT_VERSION}_checksums.txt"
fi

tar -xzf "$archive" actionlint

install_dir="${INSTALL_DIR:-${HOME}/.local/bin}"
if [ -w "$install_dir" ]; then
  install -m 0755 actionlint "${install_dir}/actionlint"
else
  sudo install -m 0755 actionlint "${install_dir}/actionlint"
fi

echo "installed actionlint ${ACTIONLINT_VERSION} to ${install_dir}/actionlint" >&2
