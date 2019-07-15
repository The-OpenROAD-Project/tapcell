#include <string>
#include <vector>
#ifdef ENABLE_TK
#include <tk.h>
#else
#include <tcl.h>
#endif//ENABLE_TK
#include <string.h>
#include <iostream>
#include <tapcell.h>

#define IMPORT_TCL(x) extern unsigned char x[];extern unsigned int x##_len;
	
#define SOURCE_TCL(x) {\
	char ch=x[x##_len-2]; \
	if(ch!='$') throw std::logic_error( "script must be $-terminated"); \
	x[x##_len-2]=0x0; if(TCL_OK!=Tcl_Eval(interp, (const char*)(x))) \
		throw std::logic_error(std::string(Tcl_PosixError(interp))); }

extern "C" int Tapcell_Init(Tcl_Interp *);

#define TCL(x) Tcl_Eval(interp, #x);
#define TCL_CATCH(x) Tcl_Eval(interp, \
		"if [catch {" #x "} err] {puts $errorInfo:$err}");

bool s_tkMode=false;

/*
DEMO ONLY. We don't usually use C-style globals, it's a code smell
*/
static Tcl_Interp * tcl_interpreter{NULL};

std::string GetTclVariable(const std::string& varName)
{
	std::string rv;
	if(tcl_interpreter)
	{
		Tcl_Obj* obj= Tcl_GetVar2Ex(tcl_interpreter, varName.c_str(), NULL,
			TCL_LEAVE_ERR_MSG);
		if(obj) rv=Tcl_GetString(obj);
	}
	return rv;
}

std::vector<std::string> GetTclList(const std::string& listName)
{
	std::vector<std::string> rv;
	if(tcl_interpreter)
	{
		Tcl_Obj* listObj= Tcl_GetVar2Ex(tcl_interpreter, listName.c_str(), 
					NULL, TCL_LEAVE_ERR_MSG);
		if(listObj)
		{
			int objc;
			Tcl_Obj **objv;
			if (Tcl_ListObjGetElements(tcl_interpreter, listObj, &objc, &objv) 
					!= TCL_ERROR) {
				for (int i=0 ; i<objc ; i++) {
					rv.push_back(Tcl_GetString(objv[i]));
					}
				}
		}
	}
	return rv;
}

IMPORT_TCL(util)
IMPORT_TCL(cmdline)

// proxy the call
extern "C" int Wrapper_Init(Tcl_Interp *interp)
{
	if (Tcl_Init(interp) == TCL_ERROR)
	{
		return TCL_ERROR;
	}

	#ifdef ENABLE_TK
	if (s_tkMode && Tk_Init(interp) == TCL_ERROR)
	{
		return TCL_ERROR;
	}
	#endif//ENABLE_TK

	// Initialize interpreter
	Tapcell_Init(tcl_interpreter=interp);

	TCL(proc quit { } { exit 0 }) // heil the EDA people
	Tcl_Eval(interp,"proc print_version { } {\n"
		"puts  \"Tcl/Tk [info tclversion]"
		" built on " __TIMESTAMP__ " by user '" __USER__ 
				"' on host '" __HOST__ "' \";\n"
		"exit 0;\n"
		"}\n");

	try {
		SOURCE_TCL(cmdline)
		SOURCE_TCL(util)
	} catch (const std::exception& e)
	{
		TCL(puts $errorInfo)
		std::cout << e.what() << std::endl;
		exit(10);
	}
	
	// By default, it adds usage as "-help" command line argument
	TCL_CATCH(
	set options {
		{version {Print version}}
		{tk {Enable Tk}}
		{lef.arg {} {LEF files to load}}
		{def.arg {} {DEF files to load}}
		{rows {Update rows definition in resulted DEF}}
		{outdef.arg {} "Output DEF, update if exists"}
		{script.arg {} {Tcl file to execute}}
		{rule.arg {120} {um checkerboard spacing distance}}
		{welltap.arg {} {Welltap macro to insert}}
		{endcap.arg {} {Endcap macro to insert}}
	}\n
	set usage " \[options] ...\noptions:"\n
	global tcl_file_to_load flagUpdateRowsDeinition;\n
	set flagUpdateRowsDefinition 0;\n
	if [ catch {
		array set params [::cmdline::getoptions argv $options $usage] 
		} ] {\n
	puts [cmdline::usage $options $usage]\n
	exit 1\n
	}\n
	if $params(version) { print_version }\n
	if { $params(script) != "" } { set tcl_script $params(script) }\n
	if { $params(lef) != "" } { set lef {}; foreach f [split [string trim $params(lef) '"']] { foreach l1 [glob $f] {lappend lef $l1} } }\n
	if { $params(def) != "" } { set def $params(def) }\n
	if $params(rows) { set flagUpdateRowsDefinition 1 } \n
	global tieCfg; \n
	if { $params(welltap) != "" } { lappend tieCfg welltap $params(welltap)} \n 
	if { $params(endcap) != "" } { lappend tieCfg endcap $params(endcap)} \n
	lappend tieCfg rule $params(rule) \n
	if { $params(outdef) != "" } {\n
		set outdef $params(outdef)\n
		default_flow $lef $def $outdef\n
		}\n
	)

	TCL_CATCH(
		if [info exists tcl_script] {source $tcl_script}
	)
	

	return TCL_OK;
}

int main(int argc,char** argv)
{
	#ifdef ENABLE_TK
	if(argc>1)
	{
		// scan for tk
		for(int i=1;i<argc;i++)
		{
			if(!strcasecmp("-tk",argv[i]))
			{
				s_tkMode=true;
				Tk_Main(argc, argv, Wrapper_Init);
				return 0;
			}
		}
	} else {
		std::cout << "Try '" << argv[0] << " -usage' for help" << std::endl;
		return 1;
		}
	#endif//ENABLE_TK

	try { Tcl_Main(argc, argv, Wrapper_Init); } catch ( 
		const std::exception& e )
	{
		std::cout << e.what() << std::endl;
	}
	tcl_interpreter=NULL;
	return 0;
}
