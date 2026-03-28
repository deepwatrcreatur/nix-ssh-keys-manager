{ lib }:

# Shared helper for collecting known_hosts data from a directory of
# *-host-ed25519.pub files and an optional ssh-config file.
{ keysDirectory, sshConfigFile ? null }:

let
  parseSSHConfig = import ./parse-ssh-config.nix { inherit lib; };

  hostToIP = if sshConfigFile != null then
    parseSSHConfig (builtins.readFile sshConfigFile)
  else {};

  hostKeyFiles = if keysDirectory != null then
    builtins.attrNames (
      lib.filterAttrs (name: type:
        type == "regular" && lib.hasSuffix "-host-ed25519.pub" name
      ) (builtins.readDir keysDirectory)
    )
  else [];

  mkEntry = file:
    let
      hostname = lib.removeSuffix "-host-ed25519.pub" file;
      key = lib.strings.trim (builtins.readFile (keysDirectory + "/${file}"));
      parts = lib.splitString " " key;
      keyType = if lib.length parts > 0 then lib.elemAt parts 0 else "ssh-ed25519";
      keyData = if lib.length parts > 1 then lib.elemAt parts 1 else "";
      ip = hostToIP.${hostname} or null;
      hostPattern = if ip != null then "${hostname},${ip}" else hostname;
    in
    {
      inherit hostname ip key keyType keyData hostPattern;
    };

  entries = map mkEntry hostKeyFiles;

  knownHostsText = lib.concatStringsSep "\n" (map (e: "${e.hostPattern} ${e.key}") entries);

in
{
  inherit hostKeyFiles hostToIP entries knownHostsText;
}
