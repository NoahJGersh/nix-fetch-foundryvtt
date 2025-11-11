{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs = {
    self,
    nixpkgs,
    ... 
  } @ inputs:
  {
    pkgOverride = import ./override.nix;
  };
}
