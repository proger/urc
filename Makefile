PROJ=	$(firstword $(basename $(wildcard *.urp)))
DB=	$(PROJ).sqlite
EXE=	./$(PROJ).exe

all: $(EXE)

%.sqlite: %.exe
	sqlite3 $@ < $*.sql

%.exe: *.ur*
	urweb -dbms sqlite -db dbname=$*.sqlite -sql $*.sql $*

clean:
	rm -f $(DB) $(EXE) $(PROJ).sql

run: $(EXE) $(DB)
	$(EXE)

tc:
	urweb -tc $(PROJ)

open:
	open http://localhost:8080/main

.PHONY: tc run clean open
