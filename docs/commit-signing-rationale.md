# Hardware-backed commit signing — rationale and constraints

Companion to `commit-signing-spec.md`. The spec says what to do; this says
why, and what breaks if you change it. Read this before deviating from a
decision in the spec.

---

## Part 1: The underlying mechanics

### Why hardware helps at all

The storage on a YubiKey is writable — you can generate, import, and delete
keys, and reset an entire applet. What does not exist is a *read* operation
for private key material. There is no command in the PIV, OpenPGP, or CTAP
wire protocol whose response contains a private key. It isn't permission
gated; the operation is absent. The interface is "sign this challenge with
slot X" and it returns a signature.

Import is therefore a one-way door: you can push a key in and destroy it,
never pull it back out. Same for OATH — `ykman` can add a TOTP seed and
cannot export one, because the HMAC is computed inside the chip.

**Consequence:** an attacker holding the device can *deny* you access (wipe
the applet, exhaust PIN counters) but that is a different capability from
extracting the credential. The whole bet rests on that distinction.

### Why a short PIN is adequate

There is no offline attack surface. You cannot image the chip and grind at
it — the retry counter is enforced by the same tamper-resistant element
holding the key. PIV defaults to 3 retries for PIN and PUK (configurable
1–255); block the PIN and you need the PUK, block both and the only
recovery is resetting the applet, destroying every key in it. FIDO2 allows
8 total attempts before the applet blocks.

A short PIN is only weak when guesses are unlimited.

### What touch actually means

Touch is the only thing in the entire stack that asserts a human was
present. Remove it and a signature stops meaning "Joel approved this" and
starts meaning "a process with access to Joel's machine produced this."

The key still can't be exfiltrated, so it proves custody — but downstream
verifiers (GitHub's Verified badge, teammates, auditors) will read it as
the human. **This is the reason agents get their own identity rather than
a touch-free version of mine.** It is an attribution argument, not a
cryptographic one.

### Phishing resistance (relevant to the FIDO2/passkey half)

In WebAuthn the browser hands the key a server challenge plus a hash of the
origin it is actually talking to, and the key signs the concatenation. The
origin hash comes from the browser, not the page, so a site at
`github.evil.com` cannot obtain an assertion bound to `github.com`. No
amount of user error changes that. This is what TOTP and SMS fail at.

Note: **you do not configure this.** User presence is required for
essentially every assertion and whether a PIN is demanded is the relying
party's call. Banking will ask for a touch every time because that is the
protocol default. The dial you actually hold is on the SSH and PIV keys you
generate yourself.

### EUCLEAK, and why firmware >= 5.7

CVE-2024-45678. Pre-5.7 YubiKey 5 devices can have an ECDSA key recovered
via electromagnetic side-channel — requiring physical disassembly and
roughly $11k of equipment. Not a realistic threat for most people, but
there's no reason to buy into it. Fixed in 5.7, which moved the underlying
RSA and ECC operations to Yubico's own cryptographic library.

Firmware is burned in at manufacture and cannot be updated. This cuts both
ways: nobody can reflash your key with malicious firmware, and nobody can
patch it either. It also means *which firmware you buy is permanent*, which
is why the spec insists on `ykman info` before provisioning.

---

## Part 2: The applet capability matrix

This table is the single most important thing in this document. Most of the
spec's decisions fall directly out of it.

| | OpenPGP | PIV | FIDO2 |
|---|---|---|---|
| Signing slots | **1** | 24 (fw 5.7) | 100 discoverable creds |
| Policy granularity | applet-wide | **per slot** | per credential |
| Policy mutable after keygen? | yes | **no** | set at creation |
| PIN session semantics | PW1, `forcesig` off | `pin-policy=once` | **none** |
| Touch options | off / on / 15s cached | never / always / 15s cached | per-cred flag |
| Duplicable to a backup key? | yes (offline master) | only via off-card keygen | **never** |
| Signature counter (audit) | **yes, monotonic** | no | no |
| Verified by GitHub as-is | yes (GPG) | no (x509, no CA chain) | yes, via SSH format |

### The option space for gates — there is no interval

PIV PIN policy is exactly three values: never, once per session, always.
Touch policy is exactly three: never, always, cached for 15 seconds. That
is the complete set. OpenPGP is comparable: `forcesig` on/off, touch
off/on/cached-15s/fixed variants.

**"Every 4 hours" does not exist as a card setting and will not.** Any
interval must be synthesized above the card, which is why the spec settles
on the physical-unplug session boundary.

### What drops each session type

- **OpenPGP PW1** (`forcesig` off): persists across signatures until the
  applet is deselected. Prompts again after unplug or reboot, not between.
  gpg-agent additionally caches the User PIN and re-supplies it when the
  card does ask, so long cache TTLs will *defeat* an unplug-based lock —
  these two mechanisms are alternatives, not complements.
- **PIV `pin-policy=once`**: persists for the card session. On YubiKey 5
  this is reported to survive PKCS#11 teardown and agent restarts, dropping
  on unplug. **Unverified — this is open question 2 in the spec.**
- **FIDO2**: no session. `verify-required` prompts per signature and
  ssh-agent does not cache FIDO2 PINs the way gpg-agent caches PW1.

---

## Part 3: Why each rejected option was rejected

Read this before reversing one.

### OpenPGP applet

Attractive because `forcesig` off gives clean PIN-once-per-insertion, and
because it is the *only* applet with a monotonic signature counter — a
genuinely useful audit primitive (record it each morning, compare against
commits the agent claims to have made; a mismatch means something signed
that you can't account for).

Killed by: one signing slot, one applet-wide policy. Cannot host a
touch-required personal identity and a touch-free agent identity on the
same device. If you only ever want one agent identity and you're willing to
buy a second key, OpenPGP is defensible and you get the counter back.

### FIDO2 `ed25519-sk` keys for agents

Attractive because policy is per-credential (so touch-free and
touch-required coexist), there are up to 100 of them, and non-resident keys
mean unplug still equals lock since the device must be present.

Killed by: no PIN session. You get either a prompt per commit or no PIN
gate at all — purely possession-based. That loses the daily-PIN property.

Two gotchas if you use them anyway:
- A *resident* sk key without `-O verify-required` means anyone holding the
  device can run `ssh-keygen -K`, extract the handle, and authenticate.
  Resident + no verify-required is genuinely "possession is everything."
- Touch-free keys are rejected for SSH *authentication* unless the server's
  `authorized_keys` entry carries the `no-touch-required` option. Signing
  doesn't care (verification ignores the presence flag) but pushing does.

### gitsign / Sigstore

Conceptually the best fit for unattended workload identity: ephemeral
keypair, OIDC identity from the workload, short-lived Fulcio cert, Rekor
transparency log, no long-lived key at all.

Killed by: GitHub shows those commits as **unverified**, because GitHub
trusts the Debian ca-certificates / Mozilla CA list and Sigstore is not in
it. The Sigstore maintainers have no control over this. Fine if your
verification is CI-side via `gitsign verify`; actively counterproductive if
anyone reads badges.

### GitHub API signing (`createCommitOnBranch`)

Genuinely the strongest option on security grounds and it was recommended
before the no-network constraint landed. Commits authored through that API
are GPG-signed by GitHub and marked verified; authorship comes from the
credential, so a GitHub App installation token produces verified commits
attributed to the App. No key material exists to protect, the token is
per-repo and expires in an hour, and revocation is uninstalling the App.

Killed by: requires a networked service. Also can't create branches, and
won't handle merge commits, symlinks, submodules, or the executable bit —
the GraphQL path treats everything as mode 100644. Tools that work around
this: DataDog `commit-headless`, Asana `push-signed-commits`, Grafana's
`github-api-commit-action`.

**If the no-network constraint ever relaxes, revisit this first.**

### A software authorization daemon

The design considered: agents don't hold a key, they call a local daemon
over a unix socket; the daemon refuses to sign unless a human
re-authorized within a configurable window, where re-authorization means
producing a signature from slot 9c (PIN + touch) over a fresh nonce.

This is the only way to get a genuinely configurable interval, and it also
gives per-agent windows and a signature log.

Killed by: ~200 lines of code that *is* your authorization boundary, and a
bug in it is a bug in that boundary. Physical key removal is a stronger
primitive than any daemon, because it cannot be bypassed by code running as
you. Rejected on maintenance cost, not on soundness — if you later want
per-agent windows, this is the design to pick up.

### x509 / PIV certs directly for commit signing

PIV can sign commits via `gpg.format = x509`, but a self-signed PIV cert
won't verify on GitHub since it doesn't chain to a CA in their trust list.
Using PIV keys through PKCS#11 as *SSH* keys sidesteps this entirely —
same hardware, same policies, signature format everyone verifies. That's
why the spec routes PIV through SSH format.

---

## Part 4: Why SSH signature format

It is the only format that verifies across all four targets:

- **GitHub**: verified, provided the key is added with type Signing Key and
  the committer email matches a verified email on the account.
- **GitLab**: verified, keys typed Authentication, Signing, or both.
- **Self-hosted / local-only**: `gpg.ssh.allowedSignersFile` — a plain text
  file mapping emails to public keys, checkable into the repo. No CA, no
  keyserver, no network. This is what satisfies the no-network requirement.

Don't reuse a key for auth and signing: both forges model them as separate
usage types, and separation means revoking an agent's push access doesn't
invalidate its past signatures.

The `allowed_signers` file is the real artifact here. It becomes the local
source of truth for which agent identities are legitimate. Treat adding a
line to it as the moment an identity comes into existence, and version it.

---

## Part 5: Backup keys — why it's not a copy

A backup YubiKey is a **second enrolled identity**, not a clone. See the
duplicability row in the matrix above.

For PIV the spec's approach is: generate independently on the backup, same
slots and policies, accept two different public keys, register both
everywhere (`allowed_signers`, GitHub, GitLab, `authorized_keys`). Tedious
once, then stable, and either device is independently revocable.

The alternative — generate off-card with openssl, import into both, destroy
the source — gives one public key everywhere and a drop-in replacement. The
concession is the private key touching a disk once. If you keep the source
file "just in case," you have thrown away the property the hardware exists
to provide.

`gpg.ssh.defaultKeyCommand` is how you avoid editing config on device swap:
have it read `ssh-add -L`, match against known primary/backup keys, and
emit whichever is present in `key::` form. (Format unverified — spec open
question 3.)

FIDO2 passkeys cannot be duplicated at all, so both keys must be enrolled
at every service, in one sitting. Some services cap you at one
authenticator and some make adding a second much harder after initial
setup. Where you can only register one, fall back to OATH TOTP — seeds are
importable, so add the same seed to both devices at enrollment.

The real failure mode is drift: enroll a service on the primary in March,
discover in October that the backup lacks it. Keep a manifest, and actually
exercise the backup quarterly. A backup you've never tested is an
assumption.

---

## Part 6: If you go further into PKI

Everything in the spec is already PIV, and PIV is X.509 PKI — currently
self-signed. Real PKI means replacing `ykman piv certificates generate`
with a CSR signed by a CA and imported back into the slot. Same keys, same
policies, same plumbing.

**PIV attestation is the standout feature.** Slot F9 holds a
Yubico-chained attestation key; `ykman piv keys attest <slot>` proves the
key was generated on-device and never existed elsewhere, plus the PIN and
touch policies it was created with. A CA that validates attestation at
enrollment can enforce "I only issue to keys in hardware with touch
required" — a policy you can prove rather than assert. Build this in from
the start if you stand up anything internal.

**One PIN per PIV applet.** Every key in every slot on a device shares one
authorization secret. This is the argument against putting a root CA and an
automated intermediate on the same device even in different slots: the PIN
unlocking your hot intermediate also unlocks your root. Hence separate
devices per tier.

Tiering: root on a dedicated key in a safe (`pin-policy=always`,
`touch-policy=always`, nothing else on the device, plugged in a handful of
times ever). Intermediate can be automated (`touch-policy=never`), bounded
by short cert lifetimes and a revocable chain. Leaf/client certs are the
ordinary slot-9a case.

Ceiling: above roughly a few issuances a minute, or if you need key backup
for a root whose loss orphans the chain, a YubiHSM 2 is the correct tool.
A TLS-terminating server needing per-connection signatures will bottleneck
on PKCS#11 — fine for a homelab, wrong for real traffic.

step-ca speaks PKCS#11 and will drive a YubiKey-held intermediate with the
root offline. Standard shape; prefer it to scripting openssl.

---

## Part 7: Secure Enclave (Phase 1) — what it is and isn't

Non-exportable and machine-bound, which is most of what hardware backing
buys for an agent key. At the point where an agent has shell on the
machine, hardware backing buys less than clean attribution does — which is
why a plain software key scoped to a bot identity and rotated is not much
worse, and why this is an acceptable interim.

Cannot be exported or backed up, by design. A new machine means new keys.
Fine for a signing key: past signatures stay verifiable, you add a line to
`allowed_signers`. It's a reason to treat this as interim rather than as a
permanent identity.

Secretive's approval prompts are deliberately local-only — no remote
approval path exists. The authenticated key is unusable away from the Mac.
Another argument for the unauthenticated key doing agent work rather than
weakening the authenticated one.

---

## Part 8: Residual risk, stated plainly

What this architecture protects against: remote credential theft, phishing,
replay, malware exfiltrating key material for later use, and a stolen
device yielding a reusable credential.

What it does not: anything running as your user between PIN entry and the
next unplug can sign. Malware timing a request to coincide with a touch you
made for your own reasons. Coercion. A stolen key plus a phished password
where the key was only a second factor.

None of those are cryptographic failures. They are the places where the
boundary this defends — private key material never crossing the USB bus —
isn't the boundary being attacked. What you keep is that a compromise
cannot outlive the session or travel to another machine. Bounding blast
radius in time and detecting it afterward is a real posture, just a
different one from preventing it.

---

## Part 9: Sourcing notes

- Buy 5C NFC, not plain 5C: Yubico lists 5C NFC at $58 USD and 5C at $65
  USD. The NFC model is cheaper *and* more capable.
- Cheapest safe Canadian source: Amazon.ca, seller "Yubico Canada Inc"
  (first-party, ~$82 CAD + HST). Yubico direct is within a few dollars
  after conversion and duty. Verify the seller field — that listing has
  multiple sellers, and Amazon commingles identical ASINs in fulfillment.
- Best Buy Canada's 5C NFC listing is a Marketplace item (third-party).
- Never eBay, Kijiji, or used, for a security key.
- Yubico runs BOGO-50% on the 5 Series during Cyber Week (Nov 20–27 in
  2023); discounted 2x 5C NFC bundles have landed near $82 USD for the
  pair. The discount is a matter of timing, not sourcing.
- Coupon aggregator sites for Yubico codes are almost entirely stale or
  invented. Ignore them.
- Anything under ~$60 CAD is old firmware, counterfeit, or a return.
