package require Tcl 8.2
package provide cmdline 1.5
namespace eval ::cmdline {
    namespace export getArgv0 getopt getKnownOpt getfiles getoptions \
	    getKnownOptions usage
}
proc ::cmdline::getopt {argvVar optstring optVar valVar} {
    upvar 1 $argvVar argsList
    upvar 1 $optVar option
    upvar 1 $valVar value
    set result [getKnownOpt argsList $optstring option value]
    if {$result < 0} {
        
        set result -1
    }
    return $result
}
proc ::cmdline::getKnownOpt {argvVar optstring optVar valVar} {
    upvar 1 $argvVar argsList
    upvar 1 $optVar  option
    upvar 1 $valVar  value
    
    set value ""
    set option ""
    set result 0
    
    if {[llength $argsList] != 0} {
	
	
	switch -glob -- [set arg [lindex $argsList 0]] {
	    "--" {
		set argsList [lrange $argsList 1 end]
	    }
	    "--*" -
	    "-*" {
		set option [string range $arg 1 end]
		if {[string equal [string range $option 0 0] "-"]} {
		    set option [string range $arg 2 end]
		}
		
		set idx [string first "=" $option 1]
		if {$idx != -1} {
		    set _val   [string range $option [expr {$idx+1}] end]
		    set option [string range $option 0   [expr {$idx-1}]]
		}
		if {[lsearch -exact $optstring $option] != -1} {
		    
		    set value 1
		    set result 1
		    set argsList [lrange $argsList 1 end]
		} elseif {[lsearch -exact $optstring "$option.arg"] != -1} {
		    set result 1
		    set argsList [lrange $argsList 1 end]
		    if {[info exists _val]} {
			set value $_val
		    } elseif {[llength $argsList]} {
			set value [lindex $argsList 0]
			set argsList [lrange $argsList 1 end]
		    } else {
			set value "Option \"$option\" requires an argument"
			set result -2
		    }
		} else {
		    
		    set value "Illegal option \"-$option\""
		    set result -1
		}
	    }
	    default {
		
	    }
	}
    }
    return $result
}
proc ::cmdline::getoptions {arglistVar optlist {usage options:}} {
    upvar 1 $arglistVar argv
    set opts [GetOptionDefaults $optlist result]
    set argc [llength $argv]
    while {[set err [getopt argv $opts opt arg]]} {
	if {$err < 0} {
            set result(?) ""
            break
	}
	set result($opt) $arg
    }
    if {[info exist result(?)] || [info exists result(help)]} {
	Error [usage $optlist $usage] USAGE
    }
    return [array get result]
}
proc ::cmdline::getKnownOptions {arglistVar optlist {usage options:}} {
    upvar 1 $arglistVar argv
    set opts [GetOptionDefaults $optlist result]
    
    
    
    
    set unknownOptions [list]
    set argc [llength $argv]
    while {[set err [getKnownOpt argv $opts opt arg]]} {
	if {$err == -1} {
            
            
            
            lappend unknownOptions [lindex $argv 0]
            set argv [lrange $argv 1 end]
            while {([llength $argv] != 0) \
                    && ![string match "-*" [lindex $argv 0]]} {
                lappend unknownOptions [lindex $argv 0]
                set argv [lrange $argv 1 end]
            }
	} elseif {$err == -2} {
            set result(?) ""
            break
        } else {
            set result($opt) $arg
        }
    }
    
    
    set argv [concat $unknownOptions $argv]
    if {[info exist result(?)] || [info exists result(help)]} {
	Error [usage $optlist $usage] USAGE
    }
    return [array get result]
}
proc ::cmdline::GetOptionDefaults {optlist defaultArrayVar} {
    upvar 1 $defaultArrayVar result
    set opts {? help}
    foreach opt $optlist {
	set name [lindex $opt 0]
	if {[regsub -- {\.secret$} $name {} name] == 1} {
	    
	}   
	lappend opts $name
	if {[regsub -- {\.arg$} $name {} name] == 1} {
	    
	    set default [lindex $opt 1]
	    set result($name) $default
	} else {
	    
	    set result($name) 0
	}
    }
    return $opts
}
proc ::cmdline::usage {optlist {usage {options:}}} {
    set str "[getArgv0] $usage\n"
    foreach opt [concat $optlist \
	     {{- "Forcibly stop option processing"} {help "Print this message"} {? "Print this message"}}] {
	set name [lindex $opt 0]
	if {[regsub -- {\.secret$} $name {} name] == 1} {
	    
	    continue
	}
	if {[regsub -- {\.arg$} $name {} name] == 1} {
	    set default [lindex $opt 1]
	    set comment [lindex $opt 2]
	    append str [format " %-20s %s <%s>\n" "-$name value" \
		    $comment $default]
	} else {
	    set comment [lindex $opt 1]
	    append str [format " %-20s %s\n" "-$name" $comment]
	}
    }
    return $str
}
proc ::cmdline::getfiles {patterns quiet} {
    set result {}
    if {$::tcl_platform(platform) == "windows"} {
	foreach pattern $patterns {
	    set pat [file join $pattern]
	    set files [glob -nocomplain -- $pat]
	    if {$files == {}} {
		if {! $quiet} {
		    puts stdout "warning: no files match \"$pattern\""
		}
	    } else {
		foreach file $files {
		    lappend result $file
		}
	    }
	}
    } else {
	set result $patterns
    }
    set files {}
    foreach file $result {
	
	
	set fullPath [file join [pwd] $file]
	
	if {[file isfile $fullPath]} {
	    lappend files $fullPath
	} elseif {! $quiet} {
	    puts stdout "warning: no files match \"$file\""
	}
    }
    return $files
}
proc ::cmdline::getArgv0 {} {
    global argv0
    set name [file tail $argv0]
    return [file rootname $name]
}
namespace eval ::cmdline {
    namespace export typedGetopt typedGetoptions typedUsage
    
    
    
    
    
    
    
    variable charclasses
    
    catch {string is . .} charclasses
    variable dummy
    regexp      -- {must be (.+)$} $charclasses dummy charclasses
    regsub -all -- {, (or )?}      $charclasses {|}   charclasses
    unset dummy
}
proc ::cmdline::typedGetopt {argvVar optstring optVar argVar} {
    variable charclasses
    upvar $argvVar argsList
    upvar $optVar retvar
    upvar $argVar optarg
    
    set optarg ""
    set retvar ""
    set retval 0
    
    if {[llength $argsList] != 0} {
        
        
        switch -glob -- [set arg [lindex $argsList 0]] {
            "--" {
                set argsList [lrange $argsList 1 end]
            }
            "-*" {
                
                set optstr ""
                foreach str $optstring {
                    lappend optstr [file rootname $str]
                }
                set _opt [string range $arg 1 end]
                set i [prefixSearch $optstr [file rootname $_opt]]
                if {$i != -1} {
                    set opt [lindex $optstring $i]
                    set quantifier "none"
                    if {[regexp -- {\.[^.]+([?+*])$} $opt dummy quantifier]} {
                        set opt [string range $opt 0 end-1]
                    }
                    if {[string first . $opt] == -1} {
                        set retval 1
                        set retvar $opt
                        set argsList [lrange $argsList 1 end]
                    } elseif {[regexp -- "\\.(arg|$charclasses)\$" $opt dummy charclass]
                            || [regexp -- {\.\(([^)]+)\)} $opt dummy charclass]} {
				if {[string equal arg $charclass]} {
                            set type arg
			} elseif {[regexp -- "^($charclasses)\$" $charclass]} {
                            set type class
                        } else {
                            set type oneof
                        }
                        set argsList [lrange $argsList 1 end]
                        set opt [file rootname $opt]
                        while {1} {
                            if {[llength $argsList] == 0
                                    || [string equal "--" [lindex $argsList 0]]} {
                                if {[string equal "--" [lindex $argsList 0]]} {
                                    set argsList [lrange $argsList 1 end]
                                }
                                set oneof ""
                                if {$type == "arg"} {
                                    set charclass an
                                } elseif {$type == "oneof"} {
                                    set oneof ", one of $charclass"
                                    set charclass an
                                }
    
                                if {$quantifier == "?"} {
                                    set retval 1
                                    set retvar $opt
                                    set optarg ""
                                } elseif {$quantifier == "+"} {
                                    set retvar $opt
                                    if {[llength $optarg] < 1} {
                                        set retval -2
                                        set optarg "Option requires at least one $charclass argument$oneof -- $opt"
                                    } else {
                                        set retval 1
                                    }
                                } elseif {$quantifier == "*"} {
                                    set retval 1
                                    set retvar $opt
                                } else {
                                    set optarg "Option requires $charclass argument$oneof -- $opt"
                                    set retvar $opt
                                    set retval -2
                                }
                                set quantifier ""
                            } elseif {($type == "arg")
                                    || (($type == "oneof")
                                    && [string first "|[lindex $argsList 0]|" "|$charclass|"] != -1)
                                    || (($type == "class")
                                    && [string is $charclass [lindex $argsList 0]])} {
                                set retval 1
                                set retvar $opt
                                lappend optarg [lindex $argsList 0]
                                set argsList [lrange $argsList 1 end]
                            } else {
                                set oneof ""
                                if {$type == "arg"} {
                                    set charclass an
                                } elseif {$type == "oneof"} {
                                    set oneof ", one of $charclass"
                                    set charclass an
                                }
                                set optarg "Option requires $charclass argument$oneof -- $opt"
                                set retvar $opt
                                set retval -3
    
                                if {$quantifier == "?"} {
                                    set retval 1
                                    set optarg ""
                                }
                                set quantifier ""
                            }
                             if {![regexp -- {[+*]} $quantifier]} {
                                break;
                            }
                        }
                    } else {
                        Error \
			    "Illegal option type specification: must be one of $charclasses" \
			    BAD OPTION TYPE
                    }
                } else {
                    set optarg "Illegal option -- $_opt"
                    set retvar $_opt
                    set retval -1
                }
            }
	    default {
		
	    }
        }
    }
    return $retval
}
proc ::cmdline::typedGetoptions {arglistVar optlist {usage options:}} {
    variable charclasses
    upvar 1 $arglistVar argv
    set opts {? help}
    foreach opt $optlist {
        set name [lindex $opt 0]
        if {[regsub -- {\.secret$} $name {} name] == 1} {
            
        }
        if {[regsub -- {\.multi$} $name {} name] == 1} {
            
            regsub -- {\..*$} $name {} temp
            set multi($temp) 1
        }
        lappend opts $name
        if {[regsub -- "\\.(arg|$charclasses|\\(.+).?\$" $name {} name] == 1} {
            
            
            set dflt [lindex $opt 1]
            if {$dflt != {}} {
                set defaults($name) $dflt
            }
        }
    }
    set argc [llength $argv]
    while {[set err [typedGetopt argv $opts opt arg]]} {
        if {$err == 1} {
            if {[info exists result($opt)]
                    && [info exists multi($opt)]} {
                
                if {$arg == ""} {
                    unset result($opt)
                } else {
                    set result($opt) "$result($opt) $arg"
                }
            } else {
                set result($opt) "$arg"
            }
        } elseif {($err == -1) || ($err == -3)} {
            Error [typedUsage $optlist $usage] USAGE
        } elseif {$err == -2 && ![info exists defaults($opt)]} {
            Error [typedUsage $optlist $usage] USAGE
        }
    }
    if {[info exists result(?)] || [info exists result(help)]} {
        Error [typedUsage $optlist $usage] USAGE
    }
    foreach {opt dflt} [array get defaults] {
        if {![info exists result($opt)]} {
            set result($opt) $dflt
        }
    }
    return [array get result]
}
proc ::cmdline::typedUsage {optlist {usage {options:}}} {
    variable charclasses
    set str "[getArgv0] $usage\n"
    foreach opt [concat $optlist \
            {{help "Print this message"} {? "Print this message"}}] {
        set name [lindex $opt 0]
        if {[regsub -- {\.secret$} $name {} name] == 1} {
            
        } else {
            if {[regsub -- {\.multi$} $name {} name] == 1} {
                
            }
            if {[regexp -- "\\.(arg|$charclasses)\$" $name dummy charclass]
                    || [regexp -- {\.\(([^)]+)\)} $opt dummy charclass]} {
                   regsub -- "\\..+\$" $name {} name
                set comment [lindex $opt 2]
                set default "<[lindex $opt 1]>"
                if {$default == "<>"} {
                    set default ""
                }
                append str [format " %-20s %s %s\n" "-$name $charclass" \
                        $comment $default]
            } else {
                set comment [lindex $opt 1]
		append str [format " %-20s %s\n" "-$name" $comment]
            }
        }
    }
    return $str
}
proc ::cmdline::prefixSearch {list pattern} {
    
    if {[set pos [::lsearch -exact $list $pattern]] > -1} {
        return $pos
    }
    
    set slist [lsort $list]
    if {[set pos [::lsearch -glob $slist $pattern*]] > -1} {
        
        set check [lindex $slist [expr {$pos + 1}]]
        if {[string first $pattern $check] != 0} {
            return [::lsearch -exact $list [lindex $slist $pos]]
        }
    }
    return -1
}
proc ::cmdline::Error {message args} {
    return -code error -errorcode [linsert $args 0 CMDLINE] $message
}

