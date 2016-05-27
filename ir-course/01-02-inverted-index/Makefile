DC = dmd
DFLAGS = -release -O -inline -boundscheck=off -I$(SRCDIR) -I$(MODULE_DIR)

SRCDIR = src
MODULE_DIR = ../..

SRCS = $(SRCDIR)/main.d $(SRCDIR)/indexer.d $(MODULE_DIR)/arsd/dom.d $(MODULE_DIR)/arsd/characterencodings.d
OBJS = main.o indexer.o dom.o characterencodings.o
OUT = task

default: $(OUT)

$(OUT): $(OBJS)
	$(DC) $(DFLAGS) $^ -of$(OUT)

main.o: $(SRCDIR)/main.d
	$(DC) $(DFLAGS) -c $<

indexer.o: $(SRCDIR)/indexer.d
	$(DC) $(DFLAGS) -c $<

dom.o: $(MODULE_DIR)/arsd/dom.d
	$(DC) $(DFLAGS) -c $<

characterencodings.o: $(MODULE_DIR)/arsd/characterencodings.d
	$(DC) $(DFLAGS) -c $<

clean:
	rm ./*.o $(OUT)

