{ lib }:

# Shared helper for collecting known_hosts data from a directory of
# *-host-*.pub files (e.g. -host-ed25519.pub, -host-rsa.pub) and an optional ssh-config file.
{ keysDirectory, sshConfigFile ? null }:

let
  parseSSHConfig = import ./parse-ssh-config.nix { inherit lib; };

  hostToIP = if sshConfigFile != null then
    parseSSHConfig (builtins.readFile sshConfigFile)
  else {};

  hostKeyFiles = if keysDirectory != null then
    builtins.attrNames (
      lib.filterAttrs (name: type:
        type == "regular"
        && lib.hasSuffix ".pub" name
        && lib.hasInfix "-host-" name
      ) (builtins.readDir keysDirectory)
    )
  else [];

  mkEntry = file:
    let
      hostname =
        let
          base = lib.removeSuffix ".pub" file;
          parts = lib.splitString "-host-" base;
        in
          if lib.length parts < 2 || lib.head parts == "" || lib.last parts == "" then
            throw "Invalid host key filename: ${file} (expected {hostname}-host-{keytype}.pub)"
          else
            lib.concatStringsSep "-host-" (lib.init parts);
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

  # Collapse multiple keys per hostname by preferring stronger algorithms
  # (ed25519 over rsa, and falling back to the first-seen type otherwise).
  entries =
    let
      weight = keyType:
        if keyType == "ssh-ed25519" then 0
        else if keyType == "ssh-rsa" then 1
        else 10;

      chooseBetter = old: new:
        if old == null then new
        else if weight new.keyType < weight old.keyType then new
        else old;

      byHost = lib.foldl' (acc: e:
        acc // {
          ${e.hostname} = chooseBetter (acc.${e.hostname} or null) e;
        }
      ) {} (map mkEntry hostKeyFiles);
    in
    map (hostname: byHost.${hostname}) (builtins.attrNames byHost);

  knownHostsText = lib.concatStringsSep "\n" (map (e: "${e.hostPattern} ${e.key}") entries);

in
{
  inherit hostKeyFiles hostToIP entries knownHostsText;
}
