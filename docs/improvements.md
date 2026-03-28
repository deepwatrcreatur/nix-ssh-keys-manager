# Improvements in nix-ssh-keys-manager

This document tracks notable improvements and ideas for future work.

## Implemented in this change

- **Unified SSH config parsing test**: Updated `test.nix` to exercise the exported `lib.parseSSHConfig` function instead of an inline duplicate implementation. This keeps the example and the library logic in sync.
- **Wildcard host coverage**: Extended the example in `test.nix` to include a `Host *` block. This ensures the parser’s wildcard-handling behavior (ignoring `Host *` entries for hostname→IP mappings) is covered by the example expression.

## Future improvement ideas

- **Stronger automated checks**: Add flake `checks` that validate `parseSSHConfig` and `readSSHKeys` against sample inputs so regressions are caught by `nix flake check`.
- **Deduplicate key-reading logic**: Refactor the NixOS `ssh-keys` module to consume the shared `lib.readSSHKeys` helper instead of re-implementing directory scanning and trimming.
- **Additional documentation**: Document the `lib.parseSSHConfig` and `lib.readSSHKeys` functions in `README.md` with short usage examples for users who want to consume them directly.
