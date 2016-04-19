DC = dmd
FLAGS = -release -O -inline -boundscheck=off -I$(SRCDIR)

SRCDIR = src
OBJDIR = .
SRCS = $(notdir $(wildcard $(SRCDIR)/*.d))
OBJS = $(addprefix $(OBJDIR)/,$(SRCS:.d=.o))
OUT = task

default: $(OUT)

$(OUT): $(OBJS)
	$(DC) $(FLAGS) $^ -of$(OUT)

$(OBJDIR)/%.o: $(SRCDIR)/%.d
	$(DC) $(FLAGS) -c $< -od$(OBJDIR)

clean:
	rm -r $(OBJDIR)/*.o $(OUT)

