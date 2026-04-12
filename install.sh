#!/bin/sh
set -eu

REPO="belulu-dev/koyomi-cli"
BINARY_NAME="koyomi"

# インストール先: 環境変数 > /usr/local/bin（存在時）> ~/.local/bin
if [ -n "${KOYOMI_INSTALL_DIR:-}" ]; then
  INSTALL_DIR="$KOYOMI_INSTALL_DIR"
elif [ -d "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
else
  INSTALL_DIR="${HOME}/.local/bin"
fi

# macOS の場合 sha256sum がなければ shasum で代替
if ! command -v sha256sum >/dev/null 2>&1; then
  if command -v shasum >/dev/null 2>&1; then
    sha256sum() { shasum -a 256 "$@"; }
  fi
fi

main() {
  validate_install_dir
  check_dependencies

  os=$(detect_os)
  arch=$(detect_arch)
  version=$(fetch_latest_version)

  echo "Installing koyomi v${version} (${os}/${arch})..."

  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  archive_name="koyomi-${version}-${os}-${arch}"
  if [ "$os" = "windows" ]; then
    archive="${archive_name}.zip"
    binary="${BINARY_NAME}.exe"
  else
    archive="${archive_name}.tar.gz"
    binary="${BINARY_NAME}"
  fi
  checksums="koyomi-${version}-checksums.txt"

  base_url="https://github.com/${REPO}/releases/download/v${version}"

  echo "Downloading ${archive}..."
  curl -fsSL "${base_url}/${archive}" -o "${tmpdir}/${archive}"
  curl -fsSL "${base_url}/${checksums}" -o "${tmpdir}/${checksums}"

  echo "Verifying checksum..."
  cd "$tmpdir"
  expected=$(grep -F "${archive}" "${checksums}" | awk '{print $1}')
  if [ -z "$expected" ]; then
    echo "Error: checksum not found for ${archive}" >&2
    exit 1
  fi
  actual=$(sha256sum "${archive}" | awk '{print $1}')
  if [ "$expected" != "$actual" ]; then
    echo "Error: checksum mismatch" >&2
    echo "  expected: ${expected}" >&2
    echo "  actual:   ${actual}" >&2
    exit 1
  fi
  echo "Checksum OK."

  echo "Extracting..."
  if [ "$os" = "windows" ]; then
    unzip -q "${archive}"
  else
    tar xzf "${archive}"
  fi

  echo "Installing to ${INSTALL_DIR}/${BINARY_NAME}..."
  if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating ${INSTALL_DIR}..."
    mkdir -p "$INSTALL_DIR"
  fi
  if [ -w "$INSTALL_DIR" ]; then
    install -m 755 "${archive_name}/${binary}" "${INSTALL_DIR}/${BINARY_NAME}"
  else
    sudo install -m 755 "${archive_name}/${binary}" "${INSTALL_DIR}/${BINARY_NAME}"
  fi

  echo "Done! koyomi v${version} installed to ${INSTALL_DIR}/${BINARY_NAME}"
  echo ""
  echo "Run 'koyomi version' to verify."
}

validate_install_dir() {
  case "$INSTALL_DIR" in
    /*) ;; # 絶対パス OK
    *) echo "Error: KOYOMI_INSTALL_DIR must be an absolute path: ${INSTALL_DIR}" >&2; exit 1 ;;
  esac
  case "$INSTALL_DIR" in
    *..*)
      echo "Error: KOYOMI_INSTALL_DIR must not contain '..': ${INSTALL_DIR}" >&2
      exit 1
      ;;
  esac
}

check_dependencies() {
  deps="curl sha256sum tar"
  os=$(uname -s)
  case "$os" in
    MINGW*|MSYS*|CYGWIN*) deps="$deps unzip" ;;
  esac
  for cmd in $deps; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: required command '${cmd}' not found" >&2
      exit 1
    fi
  done
}

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "darwin" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) echo "Error: unsupported OS: $(uname -s)" >&2; exit 1 ;;
  esac
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64)  echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) echo "Error: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
  esac
}

fetch_latest_version() {
  version=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' \
    | sed -E 's/.*"tag_name": *"v([^"]+)".*/\1/')
  if [ -z "$version" ]; then
    echo "Error: failed to fetch latest version" >&2
    exit 1
  fi
  if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Error: invalid version format: ${version}" >&2
    exit 1
  fi
  echo "$version"
}

main
