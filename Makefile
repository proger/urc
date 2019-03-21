PROJ=	urc
DB=		$(PROJ).sqlite
EXE=	./$(PROJ).exe

all: $(EXE)

%.sqlite: # %.exe
	sqlite3 $@ < $*.sql

%.exe: *.ur* *.css
	urweb $(URWEB_PATHS) -dbms sqlite -db dbname=$*.sqlite -sql $*.sql $*

clean:
	rm -f $(DB) $(EXE) $(PROJ).sql

run: $(EXE) $(DB)
	$(EXE)

tc:
	urweb -tc $(PROJ)

open:
	open http://localhost:8080/main

deps: urweb-curl

urweb-curl: release.nix urweb-curl.nix urweb-curl.json
	nix-build -o $@ -A $@ release.nix

install:
	mkdir -p $(out)/bin $(out)/sql
	cp $(EXE) $(out)/bin
	cp $(PROJ).sql $(out)/sql

.PHONY: tc run clean open
