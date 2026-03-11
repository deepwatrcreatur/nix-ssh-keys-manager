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
      
      # Parse pairs of Host/Hostname
      parseLines = lines: acc:
        if lines == [] then acc
        else
          let
            line = head lines;
            rest = tail lines;
          in
          if hasPrefix "Host " line && line != "Host *" then
            let
              hostname = removePrefix "Host " line;
              # Look ahead for Hostname line
              nextLine = if rest != [] then head rest else "";
              hasIP = hasPrefix "Hostname " nextLine || hasPrefix "HostName " nextLine;
              ip = if hasIP then 
                     removePrefix "Hostname " (removePrefix "HostName " nextLine)
                   else null;
            in
            if ip != null then
              parseLines (tail rest) (acc // { ${hostname} = ip; })
            else
              parseLines rest acc
          else
            parseLines rest acc;
    in
    parseLines cleanLines {};
  
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
  
  # Convert to known_hosts format with hostname,IP
  knownHostsEntries = concatMapStringsSep "\n" (file:
    let
      hostname = removeSuffix "-host-ed25519.pub" file;
      key = strings.trim (builtins.readFile (cfg.keysDirectory + "/${file}"));
      # Add IP if we have a mapping, otherwise just hostname
      hostPattern = if hostToIP ? ${hostname}
                    then "${hostname},${hostToIP.${hostname}}"
                    else hostname;
    in
    "${hostPattern} ${key}"
  ) hostKeyFiles;

in
{
  options.programs.ssh-known-hosts-manager = {
    enable = mkEnableOption "SSH known_hosts manager";

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

    outputFile = mkOption {
      type = types.str;
      default = ".ssh/known_hosts_managed";
      description = ''
        Output file path relative to home directory.
        Defaults to .ssh/known_hosts_managed (separate from user's known_hosts).
      '';
    };

    extraKnownHosts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Additional known_hosts entries to add directly.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Create managed known_hosts file
    home.file."${cfg.outputFile}" = {
      text = ''
        # NixOS-managed known_hosts (read-only)
        # Auto-generated from ${if cfg.keysDirectory != null then toString cfg.keysDirectory else "keys directory"}
        ${if cfg.sshConfigFile != null then "# IPs auto-extracted from ${toString cfg.sshConfigFile}" else ""}
        ${knownHostsEntries}
        ${concatStringsSep "\n" cfg.extraKnownHosts}
      '';
    };
  };
}
