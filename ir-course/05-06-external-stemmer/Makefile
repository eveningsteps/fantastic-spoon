CC = g++
LD_FLAGS=-lstdc++

DC = dmd
DFLAGS = -release -O -inline -boundscheck=off -I$(SRCDIR) -I$(INDEXER_DIR)

OBJDIR = .
SRCDIR = src
INDEXER_DIR = ../01-02-inverted-index/src


default: stemmed_index

stemmed_index: glue.o wrapper.o indexer.o main.o
	$(DC) $(DFLAGS) -L$(LD_FLAGS) $(OBJDIR)/glue.o $(OBJDIR)/wrapper.o $(OBJDIR)/indexer.o $(OBJDIR)/main.o -ofstemmed_index


glue.o: $(SRCDIR)/glue.cpp
	$(CC) -c $(SRCDIR)/glue.cpp -o $(OBJDIR)/glue.o

wrapper.o: $(SRCDIR)/wrapper.d
	$(DC) $(DFLAGS) -c $(SRCDIR)/wrapper.d -od$(OBJDIR)

indexer.o: $(INDEXER_DIR)/indexer.d
	$(DC) $(DFLAGS) -c $(INDEXER_DIR)/indexer.d -od$(OBJDIR)

main.o: $(SRCDIR)/main.d
	$(DC) $(DFLAGS) -c $(SRCDIR)/main.d -od$(OBJDIR)


clean:
	rm -r $(OBJDIR)/*.o stemmed_index

