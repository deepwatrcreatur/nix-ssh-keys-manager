# nix-ssh-keys-manager

Declarative SSH key and known_hosts management for NixOS and home-manager.

Simplifies multi-host SSH infrastructure by automatically managing `authorized_keys` and `known_hosts` from a directory of `.pub` files.

## Features

- 📁 **Directory-based key management** - Drop `.pub` files in a directory, automatically configure SSH
- 🔑 **NixOS module** - Auto-populates `authorized_keys` from directory
- 🌐 **Home-manager module** - Auto-generates `known_hosts` with hostname and IP entries
- 🔀 **Hybrid approach** - Immutable NixOS-managed keys + mutable dynamic keys
- 📝 **SSH config parsing** - Extracts hostname → IP mappings for enhanced known_hosts
- 🏷️ **Naming conventions** - `{hostname}-host-ed25519.pub` for host keys, `user@host-ed25519.pub` for user keys

## Use Cases

- **Homelabs** - Manage SSH access across multiple servers declaratively
- **Small teams** - Git-based SSH key distribution
- **DevOps** - Version-controlled SSH infrastructure
- **Personal** - Avoid manual `authorized_keys` and `known_hosts` editing

## Why Not SSH Certificates?

SSH certificates (via step-ca, Vault, etc.) are powerful but add complexity:
- Requires running a CA server
- Certificate renewal/expiry management
- More complex setup and troubleshooting

This flake provides a **simpler, git-based approach** that works great for smaller deployments. You can always migrate to SSH certificates later while keeping the directory structure.

## Installation

### 1. Add to flake inputs

```nix
{
  inputs.ssh-keys-manager.url = "github:deepwatrcreatur/nix-ssh-keys-manager";
}
```

### 2. NixOS Module (authorized_keys)

```nix
{
  imports = [ ssh-keys-manager.nixosModules.default ];

  services.ssh-keys-manager = {
    enable = true;
    username = "myuser";
    keysDirectory = ./ssh-keys;  # Directory containing *.pub files
    enableDynamicKeys = true;     # Allow manual key additions
  };
}
```

### 3. Home-manager Module (known_hosts)

```nix
{
  imports = [ ssh-keys-manager.homeManagerModules.default ];

  programs.ssh-known-hosts-manager = {
    enable = true;
    keysDirectory = ./ssh-keys;      # Directory with *-host-ed25519.pub files
    sshConfigFile = ./ssh-config;    # Optional: Parse for hostname->IP mappings
    outputFile = ".ssh/known_hosts_managed";
  };
}
```

## Directory Structure

```
your-flake/
├── ssh-keys/
│   ├── myuser@workstation-ed25519.pub    # User keys
│   ├── myuser@server1-ed25519.pub
│   ├── workstation-host-ed25519.pub      # Host keys for known_hosts
│   ├── server1-host-ed25519.pub
│   └── gateway-host-ed25519.pub
└── ssh-config                             # Optional: For IP mappings
```

## SSH Config Example

```ssh-config
Host gateway
  Hostname 10.10.10.1
  User root

Host server1
  Hostname 10.10.10.20
  User myuser
```

The home-manager module will parse this and generate:
```
gateway,10.10.10.1 ssh-ed25519 AAAA...
server1,10.10.10.20 ssh-ed25519 AAAA...
```

## Options

### NixOS Module (`services.ssh-keys-manager`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Enable the SSH keys manager |
| `keysDirectory` | `path` | `null` | Directory containing `.pub` files |
| `username` | `string` | `null` | User to configure authorized_keys for |
| `enableDynamicKeys` | `bool` | `true` | Allow manual key additions to `authorized_keys_dynamic` |
| `extraAuthorizedKeys` | `[string]` | `[]` | Additional keys to add directly |

### Home-manager Module (`programs.ssh-known-hosts-manager`)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Enable the known_hosts manager |
| `keysDirectory` | `path` | `null` | Directory containing `*-host-ed25519.pub` files |
| `sshConfigFile` | `path` | `null` | SSH config file to parse for hostname→IP mappings |
| `outputFile` | `string` | `".ssh/known_hosts_managed"` | Output file path (relative to home) |
| `extraKnownHosts` | `[string]` | `[]` | Additional known_hosts entries |

## Workflow

### Adding a New Host

1. SSH to the new host and get its host key:
   ```bash
   ssh newhost "cat /etc/ssh/ssh_host_ed25519_key.pub" > ssh-keys/newhost-host-ed25519.pub
   ```

2. Add your user key to allow access:
   ```bash
   cat ~/.ssh/id_ed25519.pub > ssh-keys/myuser@newhost-ed25519.pub
   ```

3. (Optional) Add to ssh-config:
   ```ssh-config
   Host newhost
     Hostname 192.168.1.100
     User myuser
   ```

4. Commit and rebuild:
   ```bash
   git add ssh-keys/ ssh-config
   git commit -m "Add newhost SSH keys"
   nixos-rebuild switch
   ```

### Dynamic Key Management

The hybrid approach allows temporary key additions without rebuilding:

```bash
# Add a temporary key (lasts until you remove it manually)
echo "ssh-ed25519 AAAA... temp-user@laptop" >> ~/.ssh/authorized_keys_dynamic

# Remove it later
nano ~/.ssh/authorized_keys_dynamic
```

NixOS-managed keys in `~/.ssh/authorized_keys` remain immutable and declarative.

## Comparison with Alternatives

| Approach | Complexity | Certificate Expiry | Renewal Required | Setup Time |
|----------|------------|-------------------|------------------|------------|
| **nix-ssh-keys-manager** | Low | No | No | 5 minutes |
| SSH Certificates (step-ca) | High | Yes | Yes | Hours |
| Manual management | Very Low | No | No | Per-host |
| Vault SSH | Very High | Yes | Yes | Days |

## Migration Path to SSH Certificates

This flake is compatible with future SSH certificate adoption:

1. Keep using directory-based keys (works today)
2. Set up step-ca or Vault when ready
3. Add certificate trust to your NixOS config
4. Gradually transition hosts to use certificates
5. Keep the key directory as backup/fallback

The directory structure and conventions make migration straightforward.

## License

MIT License - See LICENSE file for details.

## Contributing

Issues and pull requests welcome at https://github.com/deepwatrcreatur/nix-ssh-keys-manager

## Agent Work Queue

If you are assigning or running coding agents, start here:

- [`docs/work-items/START-HERE.md`](docs/work-items/START-HERE.md)

The seed roadmap behind that queue is tracked in [`docs/improvements.md`](docs/improvements.md).
