#$(info Mac build)
GMK=$(PDN_ROOT)/common/generated.mk
-include $(GMK)

DYN_EXT=.dynlib
DLL_DIR=$(LIB)
GCC=clang++
SWIG=/usr/local/bin/swig
LDFLAGS+=-lstdc++
RELEASE=${PDN_ROOT}

ifeq ($(USERNAME),)
USERNAME=$(shell whoami)
$(info Will be using $(USERNAME) as user name)
$(shell echo USERNAME=$(USERNAME) >> $(GMK))
endif

ifeq ($(HOSTNAME),)
HOSTNAME=$(shell hostname)
$(info Will be using $(HOSTNAME) as host name)
$(shell echo HOSTNAME=$(HOSTNAME) >> $(GMK))
endif

CXXFLAGS+=-D__HOST__='"'$(HOSTNAME)'"' -D__USER__='"'$(USERNAME)'"'
INCLUDE_TCL=-I/usr/local/Cellar/tcl-tk/8.6.9/include
LDFLAGS_TCL=-L/usr/local/Cellar/tcl-tk/8.6.9/lib -ltcl8.6 -ltk8.6

ECHO=/bin/echo