{ pkgs, ... }:

{
  packages = with pkgs; [];

  languages.zig = {
    enable = true;
    package = pkgs.zig_0_13;
  };
}
