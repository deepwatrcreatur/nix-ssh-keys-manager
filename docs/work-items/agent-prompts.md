# SSH Keys Manager Agent Prompts

Before using any prompt, read:

- [`START-HERE.md`](./START-HERE.md)

## Prompt 1: NixOS VM Integration Test

Work on [`01-nixos-vm-integration-test.md`](./01-nixos-vm-integration-test.md).

Create a branch named `test/ssh-keys-manager-nixos-vm`.

Task:
- add a proper NixOS VM integration test for `services.ssh-keys-manager`

## Prompt 2: Reuse Shared Key Reading Helper

Work on [`02-reuse-shared-key-reading-helper.md`](./02-reuse-shared-key-reading-helper.md).

Create a branch named `refactor/nixos-ssh-keys-helper-reuse`.

Task:
- refactor the NixOS module to use `lib/read-ssh-keys-map.nix`

## Prompt 3: Deterministic Output Ordering

Work on [`03-deterministic-output-ordering.md`](./03-deterministic-output-ordering.md).

Create a branch named `fix/ssh-output-ordering`.

Task:
- make generated outputs explicitly sorted and stable

## Prompt 4: Hashed Known Hosts Option

Work on [`04-hashed-known-hosts-option.md`](./04-hashed-known-hosts-option.md).

Create a branch named `feat/hashed-known-hosts-option`.

Task:
- add a hashed-hostnames option for known_hosts generation

## Prompt 5: SSH Config Parser Coverage

Work on [`05-ssh-config-parser-coverage.md`](./05-ssh-config-parser-coverage.md).

Create a branch named `test/ssh-config-parser-coverage`.

Task:
- expand parser tests for more real-world SSH config patterns

## Prompt 6: Lint And Format Checks

Work on [`06-lint-and-format-checks.md`](./06-lint-and-format-checks.md).

Create a branch named `chore/ssh-keys-manager-quality-gates`.

Task:
- add linting and formatting checks to flake checks

## Prompt 7: Remote Builder Prereqs Docs

Work on [`07-remote-builder-prereqs-docs.md`](./07-remote-builder-prereqs-docs.md).

Create a branch named `docs/remote-builder-prereqs`.

Task:
- document module prerequisites and minimal examples for remote builder keys
