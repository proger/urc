FROM nixos/nix

RUN mkdir -p /x /s
COPY . /x

WORKDIR /x
RUN nix-build -o /a release.nix
RUN nix-env -iA sqlite -f release.nix

WORKDIR /s
RUN find /a/ /x
RUN sqlite3 urc.sqlite < /a/sql/urc.sql

CMD ["/a/bin/urc.exe"]
