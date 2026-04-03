# Improvements in nix-ssh-keys-manager

This document tracks notable improvements and ideas for future work.

## Implemented improvements

- **Unified SSH config parsing test**: Updated `test.nix` to exercise the exported `lib.parseSSHConfig` function instead of an inline duplicate implementation. This keeps the example and the library logic in sync.
- **Wildcard host coverage**: Extended the example in `test.nix` to include a `Host *` block. This ensures the parser’s wildcard-handling behavior (ignoring `Host *` entries for hostname→IP mappings) is covered by the example expression.
- **Flake checks for lib helpers**: Added `checks.<system>.lib-tests` that assert `parseSSHConfig` and `readSSHKeys` behave correctly against sample inputs during `nix flake check`.
- **Module assertions for required options**: Added assertions to the SSH key and known-hosts modules to require `keysDirectory` (and `username` where applicable) when enabled, failing fast with clear messages for misconfigurations.
- **Shared SSH key-reading helper**: Introduced `lib/read-ssh-keys-map.nix` and refactored `lib/read-ssh-keys.nix` to use it, centralizing the logic for reading and trimming `.pub` keys.
- **Shared known-hosts helper and demo apps**: Introduced `lib/known-hosts.nix` and refactored both the NixOS and home-manager `ssh-known-hosts` modules to consume it, ensuring consistent host/IP resolution and known_hosts generation. The helper safely parses hostnames from `{hostname}-host-{keytype}.pub` filenames (even when hostnames contain `-host-`) and collapses multiple host keys down to a single preferred key per host (preferring `ssh-ed25519` over `ssh-rsa`). Added small `nix run .#known-hosts-demo` and `nix run .#authorized-keys-demo` apps that print sample `known_hosts` and `authorized_keys` lines derived from fixtures.

## Future improvement ideas

- **Further module deduplication**: Wire remaining modules that still contain inline key-reading logic to use the shared helpers for even more reuse.
- **Additional documentation**: Document the `lib.parseSSHConfig`, `lib.readSSHKeys`, and `lib/known-hosts.nix` helpers in `README.md` with short usage examples for users who want to consume them directly.

## Repository study notes (2026-04-03)

After reviewing the current modules, library helpers, and tests, these are the highest-impact next improvements.

### 1) Add a proper NixOS VM integration test

Current coverage is evaluation-level assertions in `flake checks` plus fixture-based helper checks. Add a VM test under `nixosTests` that boots a minimal machine, enables `services.ssh-keys-manager`, and validates:

- `/etc/ssh/authorized_keys.d/<user>` contains keys derived from fixtures.
- `~/.ssh/authorized_keys_dynamic` exists with expected ownership and mode.
- `sshd -T` resolves the expected `AuthorizedKeysFile` setting when dynamic keys are enabled.

This would catch regressions that pure evaluation tests cannot (permissions, file placement, service interactions).

### 2) Reuse shared key-reading helper in NixOS module

`modules/nixos/ssh-keys.nix` still contains inline `.pub` directory scanning and file reads. Refactor to consume `lib/read-ssh-keys-map.nix` for consistency with the rest of the codebase and to avoid duplicated parsing/trim logic.

### 3) Stabilize deterministic ordering for generated outputs

Generated key lists and known_hosts entries currently rely on `builtins.attrNames` ordering. It is usually deterministic, but explicitly sorting key material at generation time (e.g., by filename then hostname) makes rendered output stable and easier to review in Git when fixture sets grow.

### 4) Support hashed known_hosts output as an option

The home-manager known_hosts module currently emits plaintext hostnames/IPs, which is convenient but leaks inventory details if the file is shared. Add an option such as `hashHostnames = true` that renders hashed hostnames (equivalent to `ssh-keygen -H` behavior) for users with stricter privacy requirements.

### 5) Expand SSH config parser coverage for real-world patterns

`lib/parse-ssh-config.nix` intentionally handles simple `Host`/`Hostname` mappings and ignores wildcard hosts. Add tests for:

- multiple aliases in one `Host` line (`Host web web-prod`)
- mixed-case directives beyond `Hostname`/`HostName`
- duplicate host declarations with last-write-wins behavior
- comments and inline trailing comments

This clarifies intended behavior and prevents silent parser drift.

### 6) Add linting/formatting checks to flake checks

Add `nixpkgs-fmt`/`alejandra` and `statix` checks to `flake checks` so contributors get immediate feedback on style and common Nix anti-patterns.

### 7) Document remote-builder module prerequisites

`modules/common/ssh-remote-builder-keys.nix` assumes `sops.secrets` support is present. Add a README section documenting required imports (`sops-nix`) and a minimal example for both NixOS and nix-darwin consumers to reduce setup friction.
