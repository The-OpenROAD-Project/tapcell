#$(info Linux build)

GMK=$(PDN_ROOT)/common/generated.mk
-include $(GMK)

RELEASE=${PDN_ROOT}
GCC=c++
CXXFLAGS+=-fPIC
PDN_PLATFORM=Linux

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

# Tcl setup, need to auto-configure on Linux platforms
ifeq ($(INCLUDES_TCL),)
	# Check DFM standard location for Tcl 8.5
	ifneq (,$(wildcard /usr/lib64/libtcl.so))
$(info Detected Tcl and Tk libraries in /usr/lib64, assuming CentOS)
		INCLUDES_TCL=-I/usr/include
		LDFLAGS_TCL=-L/usr/lib64 -ltcl
	else
		# Not found, let's see if it is a latest Ubuntu we're runnig on?
		ifneq (,$(wildcard /usr/lib/x86_64-linux-gnu/libtcl8.6.so))
$(info Detected Tcl and Tk libraries in /usr/lib/x86_64-linux-gnu ,assuming Ubuntu)
			INCLUDES_TCL=-I/usr/include/tcl8.6
			LDFLAGS_TCL=-L/usr/lib/x86_64-linux-gnu -ltcl
		else
			$(error Unable to auto-detect Tcl configuration)
		endif
	endif
	# Cache into generated.mk
$(shell echo INCLUDES_TCL=$(INCLUDES_TCL) >> $(GMK))
$(shell echo LDFLAGS_TCL=$(LDFLAGS_TCL) >> $(GMK))
endif

# Old SWIG is deadly
ifeq ($(SWIG_VERSION),)
# Check home folder for newer swig
ifneq ($(wildcard $(HOME)/tools/bin/swig),)
SWIG=$(HOME)/tools/bin/swig
$(info found SWIG '$(SWIG)')
endif

SWIG_VERSION=$(shell $(SWIG) -version | grep Version | awk '{ print $$3 }')
SWIG_MAJOR=$(shell $(SWIG) -version | grep Version | awk '{ print $$3 }' | awk -F\. '{ print $$1 }')
ifneq ($(SWIG_MAJOR),4) 
$(error We need SWIG >= 4.0.0, please upgrade,$(SWIG) is too old)
endif
$(shell echo SWIG_VERSION=$(SWIG_VERSION) >> $(GMK))
$(shell echo SWIG=$(SWIG) >> $(GMK))
endif

# Python setup
#PYTHON_HOME=$(PDN_PYTHON)
#PYTHON_INCLUDE=$(PDN_PYTHON)/include
#INCLUDES_PYTHON+=-I$(PYTHON_INCLUDE) -I$(PYTHON_INCLUDE)/python2.7
#LDFLAGS_PYTHON+=-L$(PDN_PYTHON)/lib -lpython2.7

# Qt
#QT=$(PDN_QTDIR)
#INCLUDES_QT=-I$(PDN_QTDIR)/include
#LDFLAGS_QT=-L$(PDN_QTDIR)/lib -lQt5Core
#MOC=$(PDN_QTDIR)/bin/moc

# Boost
INCLUDES_BOOST=-I$(PDN_BOOST)/include
LDFLAGS_BOOST=-pthread -L$(PDN_BOOST)/lib -lboost_system -lboost_thread

STATIC_EXT=.a
DYN_EXT=.so
DLL_DIR=$(LIB)
EXE_EXT=

INFO_PRINT=\
	ltcl=$(TCL_HOME); \
	lpython=$(PYTHON_HOME); \
	lqt=$(QT); \
	stan=$(realpath $(STANLEY)); \
	echo "\# Tcl&Tk "$$ltcl; \
	echo "\# Python "$$lpython; \
	echo "\# Qt "$$lqt; \
	echo "";
