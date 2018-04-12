{ stdenv, fetchgit, autoreconfHook, curl, urweb }:

stdenv.mkDerivation {
  name = "urweb-curl";

  buildInputs = [
    autoreconfHook
    urweb
  ];

  propagatedBuildInputs = [
    curl
  ];

  preConfigure = ''
    export CFLAGS="-I${urweb}/include/urweb"
  '';

  src = fetchgit {
    inherit (builtins.fromJSON (builtins.readFile ./urweb-curl.json)) url rev sha256;
  };
}
