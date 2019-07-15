ifeq ($(SUBDIRS),)
all: debug
release: $(DIRS) $(LIB_TARGETS) $(BIN_TARGETS)
strip: $(LIB_TARGETS) $(BIN_TARGETS)
	@for i in $?; do \
		if [ -f $$i ] && ! [[ $$i =~ \$(STATIC_EXT)$$ ]]; then \
			echo Stripping $$i; \
			$(STRIP) $$i  2>&1 > /dev/null || $(RM) $$i; \
		fi; \
	done

release: CXXFLAGS += -Ofast

debug: $(DIRS) $(LIB_TARGETS) $(BIN_TARGETS)
debug: CXXFLAGS += -DDEBUG -g -O0 -D_GLIBCXX_DEBUG -D_GLIBXX_DEBUG_PEDANTIC

$(OBJ):; @$(MKDIR)
$(BIN):; @$(MKDIR)
$(LIB):; @$(MKDIR)

clean:; $(CLEANNING)

-include $(OBJ)/*.depend

else

TOPTARGETS:=debug release clean all strip test golden
$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	@$(MAKE) -C $@ $(MAKECMDGOALS)
.PHONY: $(TOPTARGETS) $(SUBDIRS)
info:; @$(INFO_PRINT)
clean:; $(CLEANNING)

endif

#
# Compilation rules
#

CPP_BUILD_RULE=	\
	@$(ECHO) Compiling $<; \
	$(GCC) $(CXXFLAGS) $(INCLUDES) -c -o $@ $<; \
	$(MAKE_DEPEND);

%_wrap_tcl.cpp:%tcl.i
	@echo Generating Tcl wrapper for $<
	@$(SWIG) -I$(PDN_ROOT)/public -MMD -o $@ -c++ -tcl8 $<
	@$(WRAPPER_DEPEND)

%_wrap_py.cpp:%py.i
	@echo Generating Tcl wrapper for $<
	@$(SWIG) -o $@ -c++ -python $<
	@$(WRAPPER_DEPEND)

# special cases
$(OBJ)/%_wrap_tcl.o:%_wrap_tcl.cpp
	@$(ECHO) Compiling Tcl wrapper $<
	@$(GCC) $(CXXFLAGS) -Wno-deprecated-register -Wno-register -c -o $@ $<
	@$(MAKE_DEPEND)

$(OBJ)/%_wrap_py.o:%_wrap_py.cpp
	@$(ECHO) Compiling Python wrapper $<
	@$(GCC) $(CXXFLAGS) -Wno-register -c -o $@ $<
	@$(MAKE_DEPEND)

$(OBJ)/%.o:%.cpp; $(CPP_BUILD_RULE)
$(OBJ)/%.o:%.cxx; $(CPP_BUILD_RULE)
%_moc.cpp:%.h;@echo Moc\'ing $< into $@; $(MOC) $< -o $@
	
ifeq ($(SUBDIRS),)

doc: $(DOC)

$(DOC): Doxyfile
	@$(ECHO) Generating documentation
	@$(MKDIR)
	@-$(DOXYGEN) Doxyfile

endif

.PHONY: info

include $(PDN_ROOT)/common/test.mk

check:
	@for i in `echo $(INCLUDES) | sed 's/-I//g'`;do  \
		if [ ! -d $$i ]; then echo Invalid include path: $$i; fi; \
	done; \
	for i in `echo $(LDFLAGS) | sed 's/-L//g'`;do  \
		if [ ! -d $$i ]; then echo Library path does not exist: $$i; fi; \
	done

list-include:
	@for i in `echo $(INCLUDES) | sed 's/-I//g'`;do  \
		echo $$i; \
		done;

list-libs:
	@for i in `echo $(LDFLAGS) | sed 's/-L//g'`;do  \
		echo $$i; \
		done;
	
.PHONY: check list-include list-libs
