PDN_ROOT:=$(realpath ..)
INCLUDES+=$(INCLUDES_TCL)

include $(PDN_ROOT)/common/common.mk

PROG1=$(BIN)/tapcell$(EXE_EXT)
INCLUDES += $(INCLUDE_TCL)
BIN_TARGETS=$(PROG1)
WRAPPERS=tapcell_wrap_tcl.cpp
TCL_EMBED=script_util.cpp script_cmdline.cpp
.PRECIOUS: $(TCL_EMBED)

PROG1_SOURCES := tapcell.cpp \
	swig_interface.cpp \
	$(TCL_EMBED)

PROG1_OBJS += $(PROG1_SOURCES:%.cpp=$(OBJ)/%.o)
PROG1_OBJS += $(WRAPPERS:%.cpp=$(OBJ)/%.o)
LDFLAGS += $(LDFLAGS_TCL)

.PRECIOUS: $(WRAPPERS)
EXTRA_CLEAN+=$(WRAPPERS) *.d $(TCL_EMBED)

include $(PDN_ROOT)/common/target.mk

$(PROG1): $(PROG1_OBJS); $(BUILD_EXECUTABLE)
	
# Make sure all comment removed
# sed -e 's/#.*$//' -e '/^$/d' <file>
script_%.cpp: ../script/%.tcl
	@(echo Creating binary package $@ from $<; \
	tmp=$(basename $<); \
	tmp=`basename $$tmp`; \
	sed -e 's/^#.*$$//' -e '/^$$/d' $< > $$tmp; \
	echo $$ >> $$tmp; \
	xxd -u -i $$tmp > $@; \
	rm -f $$tmp)
