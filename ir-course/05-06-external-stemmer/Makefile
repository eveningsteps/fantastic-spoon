CC = g++
LD_FLAGS+=-lstdc++

DC = dmd
DFLAGS = -release -O -inline -boundscheck=off -I$(SRCDIR) -I$(INDEXER_DIR)

SRCDIR = src
OBJDIR = .
INDEXER_DIR = ../01-02-inverted-index/src
SRCS = $(notdir $(wildcard $(SRCDIR)/*.d))
OBJS = $(addprefix $(OBJDIR)/,$(SRCS:.d=.o) glue.o indexer.o)
OUT = task


default: $(OUT)

$(OUT): $(OBJS)
	$(DC) $(DFLAGS) -L$(LD_FLAGS) $^ -of$(OUT)

$(OBJDIR)/%.o: $(SRCDIR)/%.d
	$(DC) $(DFLAGS) -c $< -od$(OBJDIR)

glue.o: $(SRCDIR)/glue.cpp
	$(CC) -c $< -o $(OBJDIR)/$@

indexer.o: $(INDEXER_DIR)/indexer.d
	$(DC) $(DFLAGS) -c $< -od$(OBJDIR)

clean:
	rm -r $(OBJDIR)/*.o $(OUT)

