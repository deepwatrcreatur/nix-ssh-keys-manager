{ lib }:

directory:
  let
    pubKeyFiles = builtins.attrNames (
      lib.filterAttrs (name: type: 
        type == "regular" && lib.hasSuffix ".pub" name
      ) (builtins.readDir directory)
    );
    
    # Read content of each public key file
    pubKeys = map (file: 
      lib.strings.trim (builtins.readFile (directory + "/${file}"))
    ) pubKeyFiles;
  in
  pubKeys
