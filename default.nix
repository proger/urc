{ stdenv, runCommand, urweb, urweb-curl, curl }:

stdenv.mkDerivation {
  name = "urc";

  buildInputs = [
    urweb
    urweb-curl
    curl
  ];

  URWEB_INCLUDE = "${urweb}/include";
  URWEB_PATHS = "-path urweb-curl ${urweb-curl}";

  src = runCommand "src" {} ''
    mkdir -p $out
    cp -R ${builtins.filterSource (p: t: p != ".git" && p != "urweb-curl" && p != "result") ./.}/* $out
    rm -f $out/urweb-curl $out/result
    ls -lah $out
    ln -sfv ${urweb-curl} $out/urweb-curl
  '';
}
