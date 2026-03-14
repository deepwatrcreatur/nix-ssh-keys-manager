# modules/common/ssh-remote-builder-keys.nix
# Cross-platform module for deploying SSH private keys for nix remote builder authentication.
# Works with sops-nix for secure secret management.
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ssh-remote-builder-keys;
  isDarwin = pkgs.stdenv.isDarwin;
  sshDirectory = if isDarwin then "/var/root/.ssh" else "/root/.ssh";
in
{
  options.services.ssh-remote-builder-keys = {
    enable = mkEnableOption "SSH remote builder key deployment via SOPS";

    keyName = mkOption {
      type = types.str;
      default = "nix-remote";
      example = "remote-builder-ed25519";
      description = ''
        Name of the SSH key file. The key will be deployed to:
        - NixOS: /root/.ssh/{keyName}
        - Darwin: /var/root/.ssh/{keyName}
      '';
    };

    sopsFile = mkOption {
      type = types.path;
      description = ''
        Path to the SOPS-encrypted file containing the SSH private key.
        This should be a path that exists in the consumer's flake.
      '';
      example = literalExpression "./secrets/nix-remote-builder-key.yaml.enc";
    };

    sopsKey = mkOption {
      type = types.str;
      default = "private_key";
      example = "ssh_private_key";
      description = ''
        The key name within the SOPS file that contains the SSH private key.
      '';
    };

    sopsFormat = mkOption {
      type = types.enum [ "yaml" "json" "binary" ];
      default = "yaml";
      description = ''
        Format of the SOPS encrypted file.
        Use "binary" if the entire file is the encrypted key.
      '';
    };

    ensureDirectory = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to ensure the SSH directory exists with correct permissions (0700).
        Set to false if the directory is managed elsewhere.
      '';
    };

    waitForSecret = mkOption {
      type = types.bool;
      default = true;
      description = ''
        NixOS only: Whether to configure nix-daemon to wait for the key to be available.
        This ensures remote builder connections work immediately after boot.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Declare the SOPS secret for the SSH private key
    sops.secrets."ssh-remote-builder-key" = {
      sopsFile = cfg.sopsFile;
      key = cfg.sopsKey;
      format = cfg.sopsFormat;
      path = "${sshDirectory}/${cfg.keyName}";
      owner = "root";
      group = if isDarwin then "wheel" else "root";
      mode = "0600";
    };

    # NixOS-specific: ensure directory exists via systemd tmpfiles
    systemd.tmpfiles.rules = mkIf (cfg.ensureDirectory && !isDarwin) [
      "d ${sshDirectory} 0700 root root - -"
    ];

    # NixOS-specific: make nix-daemon wait for sops-nix service
    systemd.services.nix-daemon = mkIf (cfg.waitForSecret && !isDarwin) {
      wants = [ "sops-nix.service" ];
      after = [ "sops-nix.service" ];
    };

    # Darwin-specific: activation script for directory
    system.activationScripts = mkIf (cfg.ensureDirectory && isDarwin) {
      sshRemoteBuilderKeyDir.text = ''
        mkdir -p ${sshDirectory}
        chmod 700 ${sshDirectory}
        chown root:wheel ${sshDirectory}
      '';
    };
  };
}
