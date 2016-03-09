CC = g++
LD_FLAGS=-lstdc++

DC = dmd
DFLAGS = -release -O -inline -boundscheck=off -I$(SRCDIR)

OBJDIR = .
SRCDIR = src


default: stemmer

stemmer: glue.o wrapper.o stemmer.o
	$(DC) $(DFLAGS) -L$(LD_FLAGS) $(OBJDIR)/glue.o $(OBJDIR)/wrapper.o $(OBJDIR)/stemmer.o -ofstemmer


glue.o: $(SRCDIR)/glue.cpp
	$(CC) -c $(SRCDIR)/glue.cpp -o $(OBJDIR)/glue.o

wrapper.o: $(SRCDIR)/wrapper.d
	$(DC) $(DFLAGS) -c $(SRCDIR)/wrapper.d -od$(OBJDIR)

stemmer.o: $(SRCDIR)/stemmer.d
	$(DC) $(DFLAGS) -c $(SRCDIR)/stemmer.d -od$(OBJDIR)


clean:
	rm -r $(OBJDIR)/*.o stemmer

