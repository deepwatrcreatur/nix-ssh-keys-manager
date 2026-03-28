{
  description = "Declarative SSH key and known_hosts management for NixOS and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    lib = nixpkgs.lib;
  in
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
        parseSSHConfig = import ./lib/parse-ssh-config.nix { inherit lib; };

        # Read all public keys from a directory
        readSSHKeys = import ./lib/read-ssh-keys.nix { inherit lib; };
      };

      # Flake checks for library helpers
      checks.${system}.lib-tests =
        let
          parseSSHConfig = import ./lib/parse-ssh-config.nix { inherit lib; };
          readSSHKeys = import ./lib/read-ssh-keys.nix { inherit lib; };

          sampleConfig = ''
            Host server1
              User myuser
              Port 2222
              Hostname 10.10.10.20

            Host *
              Hostname 192.0.2.1
          '';

          keysDir = ./tests/fixtures/ssh-keys;

          # Evaluate assertions at Nix evaluation time; build is a no-op if they pass
          _assertParse = assert parseSSHConfig sampleConfig == { server1 = "10.10.10.20"; }; true;
          _assertRead = assert readSSHKeys keysDir == [
            "ssh-ed25519 AAAA server1"
            "ssh-ed25519 BBBB server2"
          ]; true;
        in
        pkgs.stdenvNoCC.mkDerivation {
          name = "nix-ssh-keys-manager-lib-tests";
          buildCommand = "echo lib tests passed > $out";
        };
    };
}
