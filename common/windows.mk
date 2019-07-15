#$(info Windows build)

GMK=$(PDN_ROOT)/common/generated.mk
-include $(GMK)

RELEASE=$(shell cygpath ${PDN_ROOT})
PDN_PLATFORM=Windows

# Get MINGW from environment
MINGW_DIR=$(shell cygpath ${MINGW})

DYN_EXT=.dll
DLL_DIR=$(BIN)
EXE_EXT=.exe

# Boost
ifeq (${BOOST_DIR},)
PACKAGE=boost/1.68.0@conan/stable
BOOST_DIR:=$(shell cygpath `conan info $(PACKAGE) --paths -n package_folder --package-filter $(PACKAGE) | grep package_folder | awk -F\  '{ print $$2 }'`)
$(shell echo BOOST_DIR=$(BOOST_DIR) >> $(GMK))
$(info Found Boost at $(BOOST_DIR))
endif
INCLUDES+=-I$(BOOST_DIR)/include
LDFLAGS+=-I$(BOOST_DIR)/lib

LDFLAGS+=-ltcl86 -ltk86 -lpython2.7
LDFLAGS+=-L$(MINGW_DIR)/opt/lib 
LDFLAGS+=-L$(MINGW_DIR)/opt/lib/python2.7/config
LDFLAGS+=-L$(BIN)
INCLUDES+=-I$(MINGW_DIR)/opt/include/python2.7 -I$(MINGW_DIR)/opt/include

# Qt
ifeq (${QTDIR},)
PACKAGE=Qt/5.11.1@dfs/sle
QTDIR:=$(shell cygpath `conan info $(PACKAGE) --paths -n package_folder --package-filter $(PACKAGE) -s compiler.version=8.1 | grep package_folder | awk -F\  '{ print $$2 }'`)
$(shell echo QTDIR=$(QTDIR) >> $(GMK))
$(info Found Qt at $(QTDIR))
endif

INCLUDES_QT=-I$(QTDIR)/include
LDFLAGS_QT=-L$(QTDIR)/bin -lQt5Core
MOC=$(QTDIR)/bin/moc.exe

INFO_PRINT=\
	lmingw=$(MINGW_DIR)/opt/lib; \
	lpython=$(MINGW_DIR)/opt/include/python2.7; \
	lboost=$(BOOST); \
	ldp=$$PATH:$$ltcl:$$lpython:$$ltk \
	echo "\# MINGW libraries "`cygpath --dos $$lmingw`; \
	echo "\# Python libs "`cygpath --dos $$lpython`; \
	echo "\# Boost "`cygpath --dos $$lboost`; \
	echo "\# INCLUDES="$(INCLUDES); \
	echo ""; \
	ldp=$$(printf "%s" "$$ldp" | awk -v RS=':' '!a[$$1]++ { if (NR > 1) printf RS; printf $$1 }'); \
	echo export PATH=$$ldp; \
	echo "";