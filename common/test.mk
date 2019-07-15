ifeq ($(TESTSUITE),)
TESTSUITE=fast
endif

# By default, look into "tests" subfolder where we run the make
#

.PHONY: test golden

$(TESTSUITE)_TEST?=$(wildcard test/$(TESTSUITE)/*.test)

ifneq ($($(TESTSUITE)_TEST),)
#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37
RED='\033[0;31m'
NC='\033[0m' # No Color
GREEN='\033[0;32m'
test: $($(TESTSUITE)_TEST)
	@(for T in $($(TESTSUITE)_TEST); \
		do \
		. $$T; \
		$(ECHO) -n "Running test case $$NAME .."; \
		t=`mktemp`; \
		exit_code_test=-1; \
		expect_string_test=-1; \
		golden_test=-1; \
		$$COMMAND 2>&1 > $$t || exit 1; \
		if [ ! -z "$$EXIT_CODE" ]; \
		then \
			ec=$$?; \
			if [ $$ec -eq $$EXIT_CODE ] ;\
			then \
				exit_code_test=1; \
			else \
				exit_code_test=0; \
				err="Unexpected exit code $$ec, expected $$EXIT_CODE"; \
			fi; \
		fi; \
		if [ ! -z "$$EXPECT_STRING" ]; \
		then \
			rv=`grep -c $$EXPECT_STRING $$t`; \
			if [ $$rv -ne 0 ]; \
				then \
					expect_string_test=1; \
				else \
					expect_string_test=0; \
					err="String '$$EXPECT_STRING' not matched in output"; \
				fi; \
		fi; \
		if [ ! -z "$$GOLDEN" ] ; \
		then \
			g=`pwd`/`dirname $$T`/$$NAME.golden; \
			if cmp --quiet $$t $$g; \
			then \
				golden_test=1; \
			else \
				golden_test=0; \
				err=`diff $$t $$g | grep '[<>]' | head -5`; \
				err="Run: vimdiff $$t $$g"; \
			fi; \
		fi; \
		unset GOLDEN; \
		if [ "$$golden_test" -eq -1 ] && [ "$$expect_string_test" -eq -1 ] && [ "$$exit_code_test" -eq -1 ] ; \
		then \
			$(ECHO) "Test '$$T' does not test anything: test for return code, GOLDEN or String match"; \
			exit 100; \
		fi; \
		if [ "$$golden_test" -ne 0 ] && [ "$$expect_string_test" -ne 0 ] && [ "$$exit_code_test" -ne 0 ] ; then \
					printf " "$(GREEN)passed$(NC); $(ECHO) ""; \
					rm $$t; \
				else \
					printf " "$(RED)failed$(NC); $(ECHO) ""; \
					$(ECHO) $$err; \
				fi; \
		done; \
	)

golden: $($(TESTSUITE)_TEST)
	@(for T in $($(TESTSUITE)_TEST); \
		do \
		source $$T; \
		if [ ! -z "$$GOLDEN" ] ; \
		then \
			g=`pwd`/`dirname $$T`/$$NAME.golden; \
			$(ECHO) Creating GOLDEN file $$g; \
			$$COMMAND 2>&1 > $$g; \
			$(ECHO) "Dont forget to add GOLDEN file to version control"; \
			$(ECHO) "  git add $$g && git commit -am \"Adding GOLDEN for $$T\" && git push"; \
		fi; \
		done; \
	)
else
test:
golden:
endif
