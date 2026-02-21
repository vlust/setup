#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/packages.conf"

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/typecraft-dev/dotfiles}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

ensure_apt() {
  if ! command -v apt-get &>/dev/null; then
    echo "This i3 installer currently targets Ubuntu/Debian (apt-get required)."
    exit 1
  fi
}

install_packages() {
  local wanted=("$@")
  local installable=()

  for pkg in "${wanted[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
      continue
    fi

    if apt-cache show "$pkg" &>/dev/null; then
      installable+=("$pkg")
    else
      echo "Skipping unavailable apt package: $pkg"
    fi
  done

  if [[ ${#installable[@]} -gt 0 ]]; then
    sudo apt-get install -y "${installable[@]}"
  fi
}

enable_services() {
  local services=("$@")

  for service in "${services[@]}"; do
    [[ -z "$service" ]] && continue
    if ! systemctl is-enabled "$service" &>/dev/null; then
      sudo systemctl enable "$service"
    fi
  done
}

clone_or_update_dotfiles() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" pull --ff-only
    return
  fi

  if [[ -d "$DOTFILES_DIR" ]]; then
    echo "Directory exists but is not a git repository: $DOTFILES_DIR"
    exit 1
  fi

  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

stow_targets_if_present() {
  local targets=("$@")

  for target in "${targets[@]}"; do
    if [[ -d "$target" ]]; then
      stow "$target"
    else
      echo "Skipping missing stow target: $target"
    fi
  done
}

apply_dotfiles() {
  pushd "$DOTFILES_DIR" >/dev/null
  stow_targets_if_present "${COMMON_STOW_TARGETS[@]}"
  stow_targets_if_present "${I3_STOW_TARGETS[@]}"
  popd >/dev/null
}

set_default_shell_to_zsh() {
  if ! command -v zsh &>/dev/null; then
    return
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"

  if ! grep -qx "$zsh_path" /etc/shells; then
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [[ "$SHELL" != "$zsh_path" ]]; then
    chsh -s "$zsh_path"
  fi
}

install_zed() {
  if command -v zed &>/dev/null; then
    return
  fi

  curl -f https://zed.dev/install.sh | sh
}

install_uv() {
  if command -v uv &>/dev/null; then
    return
  fi

  curl -LsSf https://astral.sh/uv/install.sh | sh
}

main() {
  ensure_apt
  sudo apt-get update
  sudo apt-get upgrade -y

  install_packages "${COMMON_PACKAGES[@]}"
  install_packages "${I3_PACKAGES_UBUNTU[@]}"

  enable_services "${COMMON_SERVICES[@]}"
  enable_services "${I3_SERVICES[@]}"

  clone_or_update_dotfiles
  apply_dotfiles
  install_zed
  install_uv
  set_default_shell_to_zsh

  echo "i3 setup complete"
}

main "$@"