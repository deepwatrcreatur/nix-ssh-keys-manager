# Improvements in nix-ssh-keys-manager

This document tracks notable improvements and ideas for future work.

## Implemented improvements

- **Unified SSH config parsing test**: Updated `test.nix` to exercise the exported `lib.parseSSHConfig` function instead of an inline duplicate implementation. This keeps the example and the library logic in sync.
- **Wildcard host coverage**: Extended the example in `test.nix` to include a `Host *` block. This ensures the parser’s wildcard-handling behavior (ignoring `Host *` entries for hostname→IP mappings) is covered by the example expression.
- **Flake checks for lib helpers**: Added `checks.<system>.lib-tests` that assert `parseSSHConfig` and `readSSHKeys` behave correctly against sample inputs during `nix flake check`.
- **Module assertions for required options**: Added assertions to the SSH key and known-hosts modules to require `keysDirectory` (and `username` where applicable) when enabled, failing fast with clear messages for misconfigurations.
- **Shared SSH key-reading helper**: Introduced `lib/read-ssh-keys-map.nix` and refactored `lib/read-ssh-keys.nix` to use it, centralizing the logic for reading and trimming `.pub` keys.
- **Shared known-hosts helper**: Introduced `lib/known-hosts.nix` and refactored both the NixOS and home-manager `ssh-known-hosts` modules to consume it, ensuring consistent host/IP resolution and known_hosts generation.

## Future improvement ideas

- **Further module deduplication**: Wire remaining modules that still contain inline key-reading logic to use the shared helpers for even more reuse.
- **Additional documentation**: Document the `lib.parseSSHConfig`, `lib.readSSHKeys`, and `lib/known-hosts.nix` helpers in `README.md` with short usage examples for users who want to consume them directly.
