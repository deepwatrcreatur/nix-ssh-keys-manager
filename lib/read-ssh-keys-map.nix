{ lib }:

# Return an attribute set mapping file names to trimmed public key contents
# for all .pub files in the given directory.
directory:
  let
    dirContents = builtins.readDir directory;
    pubKeyFiles = builtins.attrNames (
      lib.filterAttrs (name: type:
        type == "regular" && lib.hasSuffix ".pub" name
      ) dirContents
    );
  in
  lib.genAttrs pubKeyFiles (file:
    lib.strings.trim (builtins.readFile (directory + "/${file}"))
  )
