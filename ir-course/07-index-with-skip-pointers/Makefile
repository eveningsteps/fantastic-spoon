DC = dmd
FLAGS = -release -O -inline -boundscheck=off -I$(SRCDIR)
OBJDIR = .
SRCDIR = src

default: searcher

searcher: searcher.o
	$(DC) $(FLAGS) $(OBJDIR)/searcher.o -ofsearcher


searcher.o: $(SRCDIR)/searcher.d
	$(DC) $(FLAGS) -c $(SRCDIR)/searcher.d -od$(OBJDIR)

clean:
	rm -r $(OBJDIR)/*.o searcher 

