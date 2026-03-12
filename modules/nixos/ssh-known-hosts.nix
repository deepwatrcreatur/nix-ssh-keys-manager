{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.ssh-known-hosts-manager;

  # Use the centralized and corrected parser
  parseSSHConfig = import ../../lib/parse-ssh-config.nix { inherit lib; };
  
  hostToIP = if cfg.sshConfigFile != null then
    parseSSHConfig (builtins.readFile cfg.sshConfigFile)
  else {};
  
  # Read host keys (pattern: {hostname}-host-ed25519.pub)
  hostKeyFiles = if cfg.keysDirectory != null then
    builtins.attrNames (
      filterAttrs (name: type: 
        type == "regular" && hasSuffix "-host-ed25519.pub" name
      ) (builtins.readDir cfg.keysDirectory)
    )
  else [];
  
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
    programs.ssh.knownHosts = mkMerge (map (file: 
      let
        hostname = removeSuffix "-host-ed25519.pub" file;
        keyContent = strings.trim (builtins.readFile (cfg.keysDirectory + "/${file}"));
        parts = splitString " " keyContent;
        keyType = if length parts > 0 then elemAt parts 0 else "ssh-ed25519";
        keyData = if length parts > 1 then elemAt parts 1 else "";
        ip = if hostToIP ? ${hostname} then hostToIP.${hostname} else null;
      in
      {
        ${hostname} = {
          hostNames = [ hostname ] ++ optional (ip != null) ip;
          publicKey = keyType + " " + keyData;
        };
      }
    ) hostKeyFiles);
  };
}
