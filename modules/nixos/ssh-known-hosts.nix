{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.ssh-known-hosts-manager;

  knownHostsFromDir = import ../../lib/known-hosts.nix { inherit lib; };

  knownHosts = knownHostsFromDir {
    keysDirectory = cfg.keysDirectory;
    sshConfigFile = cfg.sshConfigFile;
  };

  entries = knownHosts.entries;

in
{
  options.programs.ssh-known-hosts-manager = {
    enable = mkEnableOption "SSH system known_hosts manager";

    keysDirectory = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "./ssh-keys";
      description = ''
        Path to directory containing *-host-ed25519.pub files.
        Files should follow naming convention: {hostname}-host-ed25519.pub
      '';
    };

    sshConfigFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "./ssh-config";
      description = ''
        Path to ssh-config file to parse for Host -> Hostname (IP) mappings.
        When provided, known_hosts entries will include both hostname and IP.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.keysDirectory != null;
        message = "programs.ssh-known-hosts-manager.keysDirectory must be set when enable = true";
      }
    ];
    programs.ssh.knownHosts = mkMerge (map (entry:
      {
        ${entry.hostname} = {
          hostNames = [ entry.hostname ] ++ optional (entry.ip != null) entry.ip;
          publicKey = entry.keyType + " " + entry.keyData;
        };
      }
    ) entries);
  };
}
