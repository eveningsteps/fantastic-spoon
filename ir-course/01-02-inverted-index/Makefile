DC = dmd
FLAGS = -release -O -inline -boundscheck=off -I$(SRCDIR)
OBJDIR = .
SRCDIR = src

default: indexer

indexer: main.o indexer.o
	$(DC) $(FLAGS) $(OBJDIR)/main.o $(OBJDIR)/indexer.o -ofindexer


main.o: $(SRCDIR)/main.d
	$(DC) $(FLAGS) -c $(SRCDIR)/main.d -od$(OBJDIR)

indexer.o: $(SRCDIR)/indexer.d
	$(DC) $(FLAGS) -c $(SRCDIR)/indexer.d -od$(OBJDIR)


clean:
	rm -r $(OBJDIR)/*.o indexer

