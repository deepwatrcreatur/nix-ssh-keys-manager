{ lib }:

content:
  let
    lines = lib.splitString "\n" content;
    # Remove comments and trim
    cleanLines = map (line: lib.strings.trim line) (lib.filter (line: 
      !(lib.hasPrefix "#" (lib.strings.trim line)) && (lib.strings.trim line) != ""
    ) lines);
    
    # Parse pairs of Host/Hostname anywhere within the block
    parsed = lib.foldl (state: line:
      if lib.hasPrefix "Host " line then
        if line == "Host *" then
          # Bug 1 Fix: Reset currentHost for wildcard host to avoid mis-attribution
          { inherit (state) map; currentHost = null; }
        else
          # Set currentHost for a new host entry
          { inherit (state) map; currentHost = lib.removePrefix "Host " line; }
      else if state.currentHost != null && (lib.hasPrefix "Hostname " line || lib.hasPrefix "HostName " line) then
        let
          ip = if lib.hasPrefix "Hostname " line then lib.removePrefix "Hostname " line else lib.removePrefix "HostName " line;
        in
        # Bug 2 Fix: Found the Hostname, add to map and reset currentHost to null
        { map = state.map // { "${state.currentHost}" = ip; }; currentHost = null; }
      else
        # Not a line we care about for this purpose, just pass state through
        state
    ) { map = {}; currentHost = null; } cleanLines;
  in
  parsed.map
