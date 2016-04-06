DC = dmd
FLAGS = -release -O -inline -boundscheck=off -I$(SRCDIR)
OBJDIR = .
SRCDIR = src

default: searcher

searcher: main.o searcher.o
	$(DC) $(FLAGS) $(OBJDIR)/searcher.o $(OBJDIR)/main.o -ofsearcher


searcher.o: $(SRCDIR)/searcher.d
	$(DC) $(FLAGS) -c $(SRCDIR)/searcher.d -od$(OBJDIR)

main.o: $(SRCDIR)/main.d
	$(DC) $(FLAGS) -c $(SRCDIR)/main.d -od$(OBJDIR)

clean:
	rm -r $(OBJDIR)/*.o searcher

