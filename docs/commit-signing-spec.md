# Hardware-backed commit signing — implementation spec

Handoff document. Contains decisions already made, open questions that need
empirical verification, and explicit non-goals. Do not re-litigate the
decisions; do surface it if something here turns out to be factually wrong.

**Before changing any decision here, read `commit-signing-rationale.md`.**
It holds the applet capability matrix and the constraint behind each
choice. Several of these decisions look arbitrary and are not — notably
the use of SSH signature format, the separate agent identity, and the
absence of any time-based interval. If a deviation is wanted, the
rationale doc says what it costs and which alternative design to pick up
instead.

## Goal

Git commit signing where the private key cannot be exfiltrated, supporting:

1. **My own commits** — strongest available gate (biometric or PIN + touch).
2. **Autonomous agent commits** — no human interaction, including overnight.
3. **Distinct identities** — agent signatures must be attributable to the
   agent, not to me, and independently revocable.
4. **Multiple git hosts** — GitHub, GitLab, self-hosted, local-only repos.
5. **No dependency on a networked service** to produce a signature.

## Phase 1 (now): macOS Secure Enclave via Secretive

Interim solution until hardware arrives. Non-exportable, machine-bound,
zero cost.

- Tool: `brew install --cask secretive`
- Two keys, created in the Secretive UI:
  - `joel-signing` — **authentication required** (Touch ID per signature)
  - `agent-signing` — **authentication NOT required** (no prompt, ever)
- Key type is `ecdsa-sha2-nistp256`. GitHub and GitLab both verify this.
- Agent socket:
  `~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh`

### Known trap
Take the public key from `ssh-add -L` **after** exporting `SSH_AUTH_SOCK`.
The value shown in Secretive's UI differs and produces signatures that
verify nowhere.

### Known trap
Long-lived processes inherit `SSH_AUTH_SOCK` from process start. An agent
session started before a config change will not see the new value. Prefer a
stable symlink (`~/.ssh/agent.sock`) that gets repointed, over changing the
variable and expecting running processes to notice.

## Phase 2 (when hardware arrives): YubiKey 5C NFC, PIV applet

Hardware: 1x YubiKey 5C NFC primary, 1x backup (deferred on cost; watch for
Yubico's Cyber Week BOGO). Confirm firmware >= 5.7 via `ykman info` before
provisioning anything — pre-5.7 is EUCLEAK-affected. Verify authenticity at
yubico.com/genuine.

### Slot layout

PIN and touch policies are **immutable once a key is generated in a slot**.
Get this right the first time.

| Slot | PIN policy | Touch policy | Purpose |
|------|-----------|--------------|---------|
| 9a   | once      | always       | My SSH authentication |
| 9c   | always    | always       | My commit signing |
| 9d   | once      | never        | Agent commit signing |

```
ykman piv keys generate --pin-policy ALWAYS --touch-policy ALWAYS 9c /tmp/9c.pem
ykman piv keys generate --pin-policy ONCE  --touch-policy NEVER  9d /tmp/9d.pem
ykman piv certificates generate -s "joel-signing"  9c /tmp/9c.pem
ykman piv certificates generate -s "agent-signing" 9d /tmp/9d.pem
```

A slot needs a certificate before PKCS#11 will expose the key.

Verify policies actually took, rather than trusting the flags:
`ykman piv keys attest 9c` yields a cert whose ASN.1 encodes two bytes —
PIN policy (01 never, 02 once, 03 always), then touch policy (01 never,
02 always, 03 cached-15s).

### Authorization model

`pin-policy=once` means one PIN entry per card session. The session ends on
physical unplug. **Pulling the key is the intended and only lock.** No
timer-based interval, no daemon — the firmware has no configurable interval
(the only options are always / 15s cache / per-session), and a software
gate was considered and rejected as not worth the maintenance.

ssh-agent's PKCS#11 support does not hotplug, so every replug requires
re-adding the module, which is where the PIN prompt lands:

```
ssh-add -e /opt/homebrew/lib/libykcs11.dylib   # on pull
ssh-add -s /opt/homebrew/lib/libykcs11.dylib   # on insert -> PIN prompt
```

### Lock/unlock automation

Trigger on **screen lock/unlock**, not sleep — the machine is awake
overnight while agents run, so a sleep hook never fires when it matters.

- macOS: `com.apple.screenIsLocked` / `com.apple.screenIsUnlocked`
  distributed notifications, via a launchd-managed listener or Hammerspoon's
  `hs.caffeinate.watcher`.
- Linux: `Lock` / `Unlock` signals on `org.freedesktop.login1.Session`.

Requirements for the hook script:
- Both verbs idempotent — these signals fire more than once in practice.
- `SSH_ASKPASS` + `SSH_ASKPASS_REQUIRE=force` so the PIN prompt can appear
  with no TTY. Without this, unattended unlock cannot work.
- Must run in the user's GUI session (`launchctl bootstrap gui/$UID`), or
  the askpass dialog never renders.
- Fail closed. A cancelled prompt leaves the module out — correct. Never
  fall back to unsigned commits.
- Use two ssh-agents with separate sockets if my key should evict on lock
  while agents keep working: `ssh-add -e <module>` drops everything the
  module exposes, not one key.

## Verification (both phases)

Signature format is **SSH**, not OpenPGP, not x509. This is the only format
that verifies across all four targets.

```
git config --global gpg.format ssh
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
git config --global commit.gpgsign true
```

`user.signingkey` takes a `key::` literal for agent-held keys with no
private file on disk:

```
git config --global user.signingkey "key::ecdsa-sha2-nistp256 AAAA..."
```

`~/.ssh/allowed_signers` is the local source of truth. No network, no CA.
Check it into repos where collaborators need to verify.

```
joel@example.com  namespaces="git" ecdsa-sha2-nistp256 AAAA...
agent@example.com namespaces="git" ecdsa-sha2-nistp256 AAAA...
```

Forge registration:
- GitHub: add with key type **Signing Key** (not Authentication). The
  committer email must match a verified email on the account.
- GitLab: usage type Signing.
- Do not reuse one key for both auth and signing.

## Open questions — verify empirically, do not assume

1. **Which PIV slots does libykcs11 expose?** Load the module and run
   `ssh-add -L`. If retired slots 82–95 appear, there is room for
   per-agent identities. If only 9a/9c/9d/9e, there is one agent slot and
   per-agent attribution must come from the commit author field instead.
   This determines whether the multi-agent plan is viable as designed.

2. **Does `ssh-add -e` alone force a PIN prompt on re-add?** On YubiKey 5,
   PIV PIN verification is reported to survive PKCS#11 teardown and agent
   restarts, dropping only on unplug. If eviction alone does not re-prompt,
   the lock hook is soft, and a card reset is needed:
   `systemctl restart pcscd` on Linux (privileged — needs a narrow sudoers
   rule). On macOS, smartcards go through CryptoTokenKit and there is no
   known reliable reset command — physical unplug may be the only true
   reset. Test this before trusting the lock.

3. **`gpg.ssh.defaultKeyCommand` output format** for auto-selecting between
   primary and backup keys based on which is present. Verify the expected
   format against the installed git version before relying on it.

4. **Algorithm choice.** ECCP256 should be fine for git signing on current
   OpenSSH; RSA-2048 is the conservative option if anything in the chain is
   older. Test before standardising. Avoid Ed25519 for anything X.509.

## Non-goals — decided against, with reasons

- **OpenPGP applet.** Its `forcesig` session semantics were attractive, but
  the applet has one signing slot and one applet-wide policy, so it cannot
  host both a touch-required personal identity and a touch-free agent
  identity. Superseded by PIV.
- **gitsign / Sigstore.** Conceptually the best fit for workload identity,
  but GitHub renders those commits as unverified because Sigstore's root is
  not in GitHub's trusted CA list.
- **GitHub API signing (`createCommitOnBranch`).** Works well and needs no
  key material, but depends on a networked service. Explicitly ruled out.
- **`no-touch-required` on my personal key.** Produces signatures that
  read as human approval without being human approval. Agents get their own
  identity instead.
- **A software authorization daemon** enforcing a time-based interval.
  Considered; rejected as more attack surface than the key-pull it replaces.

## Task order

1. Phase 1 Secretive setup end to end; verify a signed commit shows
   Verified on GitHub and passes `git log --show-signature` locally.
2. Stable-symlink agent socket plumbing; confirm a long-running agent
   process picks up the right key.
3. Agent identity in `allowed_signers`; confirm agent commits verify and
   are attributable to the agent, not me.
4. Lock/unlock hook scripts, written against Phase 1 first (simpler, no
   card), so the plumbing is proven before hardware arrives.
5. On hardware arrival: firmware check, slot provisioning, open question
   1 and 2, then cut over.
