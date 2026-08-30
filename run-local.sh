#!/usr/bin/env bash

set -Eeuo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
env_file="${PANGOLIN_ENV_FILE:-${script_dir}/.env}"

if [[ ! -f "${env_file}" ]]; then
  printf 'Erreur : fichier d’environnement introuvable : %s\n' "${env_file}" >&2
  printf 'Créez-le avec : cp %s/.env.example %s/.env\n' "${script_dir}" "${script_dir}" >&2
  exit 1
fi

# Export all variables loaded from the local environment file for Ansible lookups.
set -a
# shellcheck disable=SC1090
source "${env_file}"
set +a

required_vars=(
  NEWT_PANGOLIN_ENDPOINT
  NEWT_ID
  NEWT_SECRET
)

missing_vars=()
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    missing_vars+=("${var_name}")
  fi
done

if (( ${#missing_vars[@]} > 0 )); then
  printf 'Erreur : variables manquantes ou vides dans %s : %s\n' \
    "${env_file}" "${missing_vars[*]}" >&2
  exit 1
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  printf 'Erreur : ansible-playbook est introuvable dans PATH.\n' >&2
  exit 1
fi

ansible_args=(
  -i 'pangolin,'
  -c local
  "${script_dir}/playbook-pangolin-upgrade.yml"
)

if (( EUID != 0 )) && ! sudo -n true 2>/dev/null; then
  ansible_args+=(--ask-become-pass)
fi

exec ansible-playbook "${ansible_args[@]}" "$@"
