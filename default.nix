{ stdenv, urweb, urweb-curl }:

stdenv.mkDerivation {
  name = "urc";

  buildInputs = [
    urweb
    urweb-curl
  ];

  URWEB_INCLUDE = "${urweb}/include";
  #URWEB_PATHS = "-path urweb-curl=${urweb-curl}";

  src = builtins.filterSource (p: t: p != ".git") ./.;
}
