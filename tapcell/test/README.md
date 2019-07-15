## Test organization

### Why test?

Idea is that any developer is able to quickly verify integirty of the software before commit or after making a small change. It also provides an effective framework for continious integration, when it's in place.

To test, in top folder or in subdir, do
```
make test
```
Test case output should than look like:
```
[dmironov@dfm pdn]$ make test
make[1]: Entering directory `/home/dmironov/pdn/tapcell'
Running test case tapcell_crash_test .. passed
Running test case tapcell_smoke_test .. failed
< /home/dmironov/pdn/tapcell > /Users/dmi/soft/pdn/tapcell
Running test case tcl_version_test .. passed
make[1]: Leaving directory `/home/dmironov/pdn/tapcell'
```
### What runs the tests?

See our [test.mk](https://github.com/abk-openroad/pdn/blob/master/common/test.mk) for details

### General structure
[Example of a test folder](https://github.com/abk-openroad/pdn/tree/master/tapcell/test/fast)

It is suggested that testcases organized into testsuites(typically smoke, nightly, release/weekly)

To execute a particular testsuite, run
```
make test TESTSUITE=nightly
```

However, by default "make test" looks into "fast" suite.

The test cases can be listed in variable `<test suite>_TEST`, or alternatively, just put it into `<subdir>/test/fast/<name>.test` and "make test" will pick it up from here

### Test file format
[Example of a test file](https://github.com/abk-openroad/pdn/blob/master/tapcell/test/fast/quick.test)

Test file is parsed for the following fields (quote strings, it's essentially a bash script):

```
NAME=my_first_test

DESCRIPTION="Example of test case"
PLATFORM=all
COMMAND=date
```

To process a test, use any/all of the following:
```
GOLDEN=1
EXIT_CODE=0
EXPECT_STRING="May"
```
EXIT_CODE is typically 0, which indicates the command compelted successfully. If you return a custom code from main(), please set it here. It's optional

EXPECT_STRING is grepped against test output. Test passes, if it's found at least one time.

GOLDEN indicates that we want to capture both STDIO and STDERR and compare it vs "golden", i.e. last known "good" run.
We can capture GOLDEN file automatically. A GOLDEN file should be kept under source control.
Technically, we name it `<test>.golden` and keep in the same folder where `<name>.test` is located, default path is `<subdir>/test/fast/<name>.test`
To generate golden file, do "make golden" in the subdir and don't forget to add it to a source control:
```
[dmironov@dfm tapcell]$ pwd
/home/dmironov/pdn/tapcell
[dmironov@dfm tapcell]$ make golden
Creating GOLDEN file /home/dmironov/pdn/tapcell/test/fast/tapcell_crash_test.golden
Dont forget to add GOLDEN file to version control
  git add /home/dmironov/pdn/tapcell/test/fast/tapcell_crash_test.golden && git commit -am "Adding GOLDEN for test/fast/crash.test" && git push
Creating GOLDEN file /home/dmironov/pdn/tapcell/test/fast/tapcell_smoke_test.golden
Dont forget to add GOLDEN file to version control
  git add /home/dmironov/pdn/tapcell/test/fast/tapcell_smoke_test.golden && git commit -am "Adding GOLDEN for test/fast/quick.test" && git push
```
To clean test artifacts with "make clean" command, list it's wild card pattern in this variable
```
CLEAN="tmp.txt *~"
```
