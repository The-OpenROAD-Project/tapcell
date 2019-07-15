# 
# Development sample (to become part of placer)
#
# Scan PDB.cfg in the development folder to extract special cell classes
#
proc scan_cell_class { class fn } {
	puts -nonewline "Scanning '$fn' for '$class' cells .."
	set f [open $fn r]
	set macro ""
	set macro_line 0
	set line_num 0
	set Ms {}
	foreach line [split [read $f] "\n"] {
		incr line_num
		if { "$macro" != "" } {
			if [regexp -nocase "END\s+$macro" $line] {
				# end of macro
				set macro ""
				set marco_line 0
				continue
				}
			if [regexp -all -nocase "CLASS.*$class" $line] {
				#puts "$macro_line: $class $macro"
				lappend Ms $macro
				} 
			}
		if [regexp -nocase {MACRO\s+(\S+)} $line -> macro] {
			set macro_line $line_num
			}
				
		}
	close $f
	set rv [lsort -u $Ms]
	unset Ms
	if [llength $rv] {
		puts "found [llength $rv] cells"
		} else {
			puts "not found"
			}
	return $rv
	}

puts {Executing Tapcell scenario}

foreach dir { ./ test ../test [file dir $argv0]} {
	set pdncfg $dir/PDN.cfg
	if [file exist $pdncfg] {
		break
		}
	set pdncfg ""
	}
	
if { $pdncfg == "" } {
	puts "Could not find PDN.cfg"
	exit 1
	}
	
source $pdncfg

set welltaps {}
set endcaps {}
foreach lef $::cellLef {
	set wt [scan_cell_class WELLTAP $lef]
	if [llength $wt] {
		set welltaps [lappend welltaps $wt]
		}
	unset wt
	set ec [scan_cell_class ENDCAP $lef]
	if [llength $ec] {
		set endcaps [lappend endcaps $ec]
		}
	unset ec
	}
puts "Welltaps: $welltaps"
puts "Endcaps: $endcaps"
puts {Tapcell placement completed}
