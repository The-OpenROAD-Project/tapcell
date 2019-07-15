
SYS := $(shell gcc -dumpmachine)
SWIG?=swig
MD=mkdir -p
ECHO?=echo
RM=rm -f
AR=ar
STRIP=strip

# PROFILE=-pg
#CXXFLAGS=-std=c++17 $(PROFILE) -Wno-c++2a-extensions
CXXFLAGS=-std=c++2a $(PROFILE)
LDFLAGS=-lstdc++
MOC=moc
GCC=g++
STATIC_LIB_EXT=.a

ifeq ($(PDN_ROOT),)
	$(error Running PDN build depends on setting PDN_ROOT env var, as a build root)
endif

ifneq (, $(findstring darwin, $(SYS)))
	-include $(PDN_ROOT)/common/mac.mk
	else
		ifneq (, $(findstring linux, $(SYS)))
		-include $(PDN_ROOT)/common/linux.mk
		else
			ifneq (, $(findstring mingw, $(SYS)))
			-include $(PDN_ROOT)/common/windows.mk
			else
				$(error $(SYS) is not a supported platform)
			endif # Windows
	endif # Linux
endif # darwin

BIN=$(RELEASE)/bin
LIB=$(RELEASE)/lib
DOC=$(RELEASE)/doc
OBJ=.obj
DIRS=$(BIN) $(LIB) $(OBJ)


INCLUDES+=-I. -I$(PDN_ROOT)/public

INCLUDES+=-I$(PDN_ROOT)
CXXFLAGS+=$(INCLUDES) -Wfatal-errors

ifneq ($(LIB),)
LDFLAGS+=-L$(LIB)
endif

MKDIR=@if [ ! -d $@ ]; then echo "Creatng folder $@"; $(MD) -p $@; fi

BUILD_DYNAMIC_LIBRARY=@$(ECHO) Creating dynamic library $@;\
	$(GCC) -shared -o $@ $^ $(LDFLAGS) $(PROFILE)

BUILD_STATIC_LIBRARY=@$(ECHO) Creating static library $@;\
	$(AR) rcs $@ $^

BUILD_EXECUTABLE=@$(ECHO) Building executable $@;\
	$(GCC) -o $@ $^ $(LDFLAGS) $(PROFILE)

CLEANNING=@$(RM) -r $(OBJ) .obj $(DOC) Doxyfile.bak \
	$(LIB_TARGETS) $(BIN_TARGETS) *~ $(EXTRA_CLEAN) *_wrap.cpp ui_*.h; \
	for i in $(TARGET); do $(RM) -fr $$i $$i.dSYM; done; \
	ccache-swig -C 2>&1 > /dev/null;

MAKE_DEPEND=\
	x=$(OBJ)/$*.depend; \
	if [ ! -f  $$x ]; then \
		printf $(OBJ)/ > $$x; $(GCC) -MP -MM $(CXXFLAGS) -c $<  >> $$x || rm -f $$x; \
	fi

WRAPPER_DEPEND = \
	if [ ! -d $(OBJ) ]; then mkdir -p $(OBJ); fi; \
	$(ECHO) $@:$< > $(OBJ)/$*.depend; \
	(f=$*_wrap_*.d; if [ -f $$f ]; then mv $$f $(OBJ)/; fi; cd $(OBJ); for i in *.d; do mv $$i $$(basename $$i .d).depend; done;)
	
SYMLINK=\
	@$(ECHO) Symlinking $< to $@; \
	ln -sf $< $@
	
COPY=\
	@$(ECHO) Copying $< to $@; \
	cp -f $< $@

NOTHINGTODO=@echo Skipping $@, nothing to do
