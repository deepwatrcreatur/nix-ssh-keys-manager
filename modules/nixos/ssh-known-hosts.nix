{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.ssh-known-hosts-manager;
  
  # Parse ssh-config to extract hostname -> IP mappings
  parseSSHConfig = content:
    let
      lines = splitString "\n" content;
      # Remove comments and trim
      cleanLines = map (line: strings.trim line) (filter (line: 
        !(hasPrefix "#" (strings.trim line)) && (strings.trim line) != ""
      ) lines);
      
      # Parse pairs of Host/Hostname anywhere within the block
      parsed = foldl (state: line:
        if hasPrefix "Host " line && line != "Host *" then
          { inherit (state) map; currentHost = removePrefix "Host " line; }
        else if state.currentHost != null && (hasPrefix "Hostname " line || hasPrefix "HostName " line) then
          let
            ip = if hasPrefix "Hostname " line then removePrefix "Hostname " line else removePrefix "HostName " line;
          in
          { map = state.map // { "${state.currentHost}" = ip; }; currentHost = state.currentHost; }
        else
          state
      ) { map = {}; currentHost = null; } cleanLines;
    in
    parsed.map;
  
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
