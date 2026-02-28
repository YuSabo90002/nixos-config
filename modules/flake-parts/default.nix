{ inputs, ... }:
{
  systems = [ "x86_64-linux" ];
  imports = [
    inputs.nixos-unified.flakeModules.default
    inputs.nixos-unified.flakeModules.autoWire
  ];
}
