# shellcheck shell=bash disable=SC2154 # provider and identities come from secure-enclave.nix.
# Converges this Mac's Secure Enclave on the signing identities
# secure-enclave.nix declares, and is safe to run again. Provisioning is
# imperative because key generation is: an enclave key can't be reproduced
# from a derivation.
#
# secure-enclave.nix gives it, through the environment, the provider OpenSSH
# reaches the enclave through, as $provider, and the identities, as
# $identities: one a line, each its label, protection, name and email,
# separated by tabs. SE_KEYS_CMD chooses what it does: ensure (the default)
# or status.

readonly sc=/usr/sbin/sc_auth
readonly kg=/usr/bin/ssh-keygen
readonly dest="$HOME/.ssh"

list_ssh() { "$sc" list-ctk-identities -t ssh | tail -n +2; }
fp_of() { list_ssh | awk -v l="$1" '$4 == l { print $2 }'; }
count() { list_ssh | grep -c . || true; }

ensure_identity() {
  local label="$1" prot="$2" cn="$3" email="$4"
  if [ -n "$(fp_of "$label")" ]; then
    echo "  identity $label: present ($prot)"
    return 0
  fi
  echo "  identity $label: creating ($prot)"
  "$sc" create-ctk-identity -l "$label" -k p-256-ne -t "$prot" -N "$cn" -E "$email"
}

# ssh-keygen -K writes every resident credential to the same filename and
# prompts to overwrite (Apple FB21992630). Answering y k-1 times then n
# deterministically yields credential number k, so this walks k until the
# fingerprint matches the identity wanted.
export_handle() {
  local label="$1" want n k tmp fp
  want="$(fp_of "$label")"
  if [ -z "$want" ]; then
    echo "  no identity $label" >&2
    return 1
  fi

  if [ -f "$dest/$label.pub" ] &&
    [ "$("$kg" -lf "$dest/$label.pub" | awk '{print $2}')" = "$want" ]; then
    echo "  handle   $label: present"
    return 0
  fi

  n="$(count)"
  for k in $(seq 1 "$n"); do
    tmp="$(mktemp -d)"
    {
      if [ "$k" -gt 1 ]; then yes y | head -n "$((k - 1))"; fi
      yes n | head -n "$((n - k + 1))"
    } | (
      cd "$tmp" &&
        SSH_ASKPASS_REQUIRE=force SSH_ASKPASS=/usr/bin/true \
          "$kg" -K -w "$provider" -N "" >/dev/null 2>&1
    ) || true

    if [ -f "$tmp/id_ecdsa_sk_rk.pub" ]; then
      fp="$("$kg" -lf "$tmp/id_ecdsa_sk_rk.pub" | awk '{print $2}')"
      if [ "$fp" = "$want" ]; then
        install -m 600 "$tmp/id_ecdsa_sk_rk" "$dest/$label"
        install -m 644 "$tmp/id_ecdsa_sk_rk.pub" "$dest/$label.pub"
        rm -rf "$tmp"
        echo "  handle   $label: installed"
        return 0
      fi
    fi
    rm -rf "$tmp"
  done
  echo "  could not export a handle for $label" >&2
  return 1
}

ensure() {
  local label prot cn email
  # Never enable these for login: a login-capable CTK identity is reported
  # to degrade the login window to a bogus-PIN prompt.
  "$sc" pairing_ui -s disable >/dev/null 2>&1 || true
  # The identities come in on their own descriptor, so nothing the loop runs
  # reads them from its input.
  while IFS=$'\t' read -r -u 3 label prot cn email; do
    ensure_identity "$label" "$prot" "$cn" "$email"
    export_handle "$label"
  done 3<<<"$identities"
  echo
  echo "public keys, which belong in allowed_signers, declared in nix:"
  for f in "$dest"/joel-signing.pub "$dest"/agent-signing.pub; do
    [ -f "$f" ] && echo "  $(cut -d' ' -f1-2 "$f")"
  done
}

main() {
  case "${SE_KEYS_CMD:-ensure}" in
  ensure) ensure ;;
  status) list_ssh ;;
  *)
    echo "usage: SE_KEYS_CMD=ensure|status se-keys" >&2
    exit 64
    ;;
  esac
}

main
