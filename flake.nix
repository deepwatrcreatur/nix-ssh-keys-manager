{
  description = "Declarative SSH key and known_hosts management for NixOS and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    {
      # NixOS module for authorized_keys management
      nixosModules = {
        default = import ./modules/nixos/ssh-keys.nix;
        ssh-keys = import ./modules/nixos/ssh-keys.nix;
        ssh-known-hosts = import ./modules/nixos/ssh-known-hosts.nix;
        ssh-remote-builder-keys = import ./modules/common/ssh-remote-builder-keys.nix;
      };

      # Darwin modules
      darwinModules = {
        ssh-remote-builder-keys = import ./modules/common/ssh-remote-builder-keys.nix;
      };

      # Home-manager module for known_hosts management
      homeManagerModules = {
        default = import ./modules/home-manager/ssh-known-hosts.nix;
        ssh-known-hosts = import ./modules/home-manager/ssh-known-hosts.nix;
      };

      # Reusable library functions
      lib = {
        # Parse ssh-config file to extract Host -> Hostname mappings
        parseSSHConfig = import ./lib/parse-ssh-config.nix { inherit (nixpkgs) lib; };
        
        # Read all public keys from a directory
        readSSHKeys = import ./lib/read-ssh-keys.nix { inherit (nixpkgs) lib; };
      };
    };
}
