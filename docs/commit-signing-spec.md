# Commit Signing: What Signs Now

Every commit and tag Joel's machines make is signed, with a key held in the
machine's own hardware, where it can't be copied out. core.nix builds all
of it; this repository says only who may sign. [The
rationale](commit-signing-rationale.md) says why the design is what it is,
and which of its first choices were since replaced.

## Two Keys on Every Machine

core.nix's `signing` module gives git its settings and the program it signs
with, which picks one of two keys each time it signs:

| Key             | Asks                                   | Signs for                  |
| --------------- | -------------------------------------- | -------------------------- |
| `joel-signing`  | Touch ID, or a PIN then a confirmation | Joel, at a terminal        |
| `agent-signing` | nothing, ever                          | pi and the other harnesses |

When git's standard input is a terminal and the controlling terminal
opens, a person is at the keyboard and Joel's key signs; otherwise a
harness is driving git over pipes and the agents' key signs. `SIGN_AS=joel`
or `SIGN_AS=agent` decides it outright. The program checks each signature
it makes, and takes back one that doesn't verify. The format is SSH's, the
only one every forge and plain git verify.

## The Hardware

- **methuselah** keeps both keys in its Secure Enclave, through core.nix's
  `secure-enclave-signing` module. They're CryptoTokenKit identities, made
  by its `se-keys` with `sc_auth create-ctk-identity`, and OpenSSH reaches
  them through the Mac's own `ssh-keychain.dylib`, with no agent and no
  socket. A switch never makes them; it says when one is missing.
- **penelope** keeps both in its TPM, through core.nix's `tpm-signing`
  module, held by `ssh-tpm-agent`: Joel's asks for its PIN once a session
  and a confirmation on every signature, and the agents' signs through an
  agent of its own that asks nothing. The guide made them at its first
  start.

Neither machine's keys can be exported or backed up; a lost machine's keys
go with it, and a new one makes its own.

## Who May Sign

`personal/signers.nix` lists every key that may sign, as its public half:
Joel's own and his agents', on both machines, and the 1Password key that
signed before the hardware did. `personal/home.nix` writes them into git's
allowed signers, every one under `joel@grrbrr.ca`, since a forge shows
Verified only when the committer email is a verified address on the
account, and that's the only one. Whose commit it is lives in the committer
name, which methuselah's harnesses give as Joel's with `(agent)` after it
(`machines/methuselah/home.nix`), and in the key's fingerprint.

The list only grows. A key is retired by adding `valid-before="YYYYMMDD"`
to its line, never by deleting it, since git checks the bounds against the
commit's own time, so everything it signed earlier stays verifiable. Each
key is revoked on its own, on GitHub and GitLab alike, where it's added as a
signing key and never as an authentication key.

## What a Machine Updating Itself Trusts

`update-to-main` builds main only when its head was signed by GitHub,
merging a change (`personal/github-merges.asc`), or by one of Joel's own
keys. It trusts none of the agents' keys, so no agent's commit alone can
change what a machine runs.

## Changing It

How keys are made, picked and reached is core.nix's, in its `signing`,
`secure-enclave-signing` and `tpm-signing` modules; change it there. A new
key's public half goes into `personal/signers.nix` here, under `joel` or
`agents`.
