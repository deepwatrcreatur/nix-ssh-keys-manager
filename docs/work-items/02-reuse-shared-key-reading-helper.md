Status: `ready`
Suggested branch: `refactor/nixos-ssh-keys-helper-reuse`
Priority: `high`

# Reuse Shared Key Reading Helper

## Goal

Refactor `modules/nixos/ssh-keys.nix` to use the shared key-reading helper for
consistency and less duplicated parsing logic.
