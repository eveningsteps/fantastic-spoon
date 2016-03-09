DC = dmd
FLAGS = -release -O -inline -boundscheck=off
OBJDIR = .
SRCDIR = src

default: indexer

indexer: indexer.o
	$(DC) $(FLAGS) $(OBJDIR)/indexer.o -ofindexer

indexer.o: $(SRCDIR)/indexer.d
	$(DC) $(FLAGS) -c $(SRCDIR)/indexer.d -od$(OBJDIR)

clean:
	rm -r $(OBJDIR)/*.o indexer

