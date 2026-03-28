{ lib }:

directory:
  let
    readSSHKeysMap = import ./read-ssh-keys-map.nix { inherit lib; };
    keyMap = readSSHKeysMap directory;
    files = builtins.attrNames keyMap;
  in
  map (file: keyMap.${file}) files
