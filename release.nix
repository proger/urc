# You can build this repository using Nix by running:
#
#     $ nix-build release.nix
#
# You can also open up this repository inside of a Nix shell by running:
#
#     $ nix-shell
#
# ... and then Nix will supply the correct Haskell development environment for
# you
#
# Last tested version:
# 18.03pre128481.1098c071e59
#
{ pkgs ? import <nixpkgs> {} }:
let
  name = "urc";

  config = {
    packageOverrides = pkgs: {
      urweb-curl = pkgs.callPackage ./urweb-curl.nix {};
      "${name}" = pkgs.callPackage ./. {};
    };
  };

  custom-pkgs =
    import pkgs.path { inherit config; inherit (pkgs) system; };
in
{
  release = custom-pkgs."${name}";
  inherit (custom-pkgs) urweb-curl urweb sqlite;
}
