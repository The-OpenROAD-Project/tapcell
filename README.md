### Before you start

## tapcell usage

Tapcell is a point tool physical cell insertion stadalone command line application. Core algorithm part is done in standard template C++17, while general business logic, configuration, scenario, LEF/DEF parsing is coded in Tcl and Tcl is compiled into exectuable.

Library rules currenly passed as command line arguments:
```
tapcell -lef $lef -def $def -outdef $odef -rule 120 -welltap $welltap_macro -endcap $endcap_macro 
```
  
Tapcell takes list of LEF files (can be wild-carded list), DEF file with core definition and output DEF file. If output DEF file already exists (so it has floorplan and other sections), tapcell will update component section only. If output DEF file does not exist, new file will be created.

Popular physical design backend tools are often limited when it comes to processing complex placement constraint and hard macro configurations. To better faciliate combined flows, it is possible to re-generate ROWS definitions in DEF. To achieve that, use command line switch "-rows" 

Usage is reported from command line
```
> tapcell -usage
tapcell  [options] ...
options:
 -version             Print version
 -tk                  Enable Tk
 -lef value           LEF files to load <>
 -def value           DEF files to load <>
 -rows                Update rows definition in resulted DEF
 -outdef value        Output DEF, update if exists <>
 -script value        Tcl file to execute <>
 -rule value          um checkerboard spacing distance <120>
 -welltap value       Welltap macro to insert <>
 -endcap value        Endcap macro to insert <>
 --                   Forcibly stop option processing
 -help                Print this message
 -?                   Print this message
```

## GCC >= 8.3.0

tapcell is using GCC C++17 standard and relies on gcc 8.3.0+
Please make sure it's enabled in your enviornment
```
module load gcc/8.3.0
```
## SWIG >= 4.0.0

We need SWIG higher than 4. It's built locally in /home/dmironov/bin/swig
It's advised you don't rely on it and install your own.
Makefiles have a check for SWIG version, should report 4+

```
swig -version
```
## Innouvs for tap cell placement verfication
Please load innovus 18+ for placement checks
```
module load innovus
```

## Welltap/Endcap Insertion test
### Test organization
To learn how to setup and run "make test", please see the [readme](https://github.com/abk-openroad/pdn/tree/master/tapcell/test)

### Build tapcell
```
git clone git@github.com:abk-openroad/pdn.git
make release
tapcell -version # Should work, print host, user, build time
make test
```

### Run test design
tapcell must be in the PATH and print version before running it
```
ssh -X dfm
git clone /home/dmironov/testdesign.git
cd testdesign/aes/
./run.sh
```
