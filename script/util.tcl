#
# Production library. Do not use directly!
#
# Tcl library to facilitate LEF/DEF features extraction
#
proc extract_lef_macro_and_site { macro_names lef } {
	set rv ""
	set f [open $lef r]
	set txt [read $f]]
	close $f
	set linecnt 0
	set macro_line 0
	set macro ""
	set site_names {}
	# Step 1. Scan for MACRO definitions
	foreach line [split $txt "\n" ] {
		incr linecnt
		# macro proc
		if { $macro_line != 0  } {
			append rv "$line\n"
			if [regexp -all -nocase "END\\s+$macro" $line] {
				set macro_line 0
				} else {
					if [regexp -nocase {SITE\s+(\S+)} $line -> site] {
						lappend site_names $site
						}
					}
			continue
			}
		if [regexp -nocase {MACRO\s+(\S+)} $line -> macro] {
			if { -1 != [lsearch -exact $macro_names $macro] } {
				append rv "$line\n"
				set macro_line $linecnt
				}
			continue
			}

		}
	# Step 2. Scan of SITE definitions
	set srv ""
	set linecnt 0
	set site_line 0
	set site ""
	foreach line [split $txt "\n" ] {
			incr linecnt
			if { $site_line != 0  } {
				append srv "$line\n"
				if [regexp -all -nocase "END\\s+$site" $line] {
					set site_line 0
					set idx [lsearch $site_names $site]
					set site_names [lreplace $site_names $idx $idx]
					if { ! [llength $site_names] } {
						break
						}
					}
					continue
				}
			if [regexp -nocase {SITE\s+(\S+)} $line -> site] {
				if { -1 != [lsearch -exact $site_names $site] } {
					append srv "$line\n"
					set site_line $linecnt
				}
			continue
			}
		}
	return "$srv$rv"
	}

proc extract_row_definitions { def } {
	set rv ""
	set linecnt 0
	set line ""
	set f [open $def r]
	foreach line [split [read $f] "\n"] {
		incr linecnt
		# Special lines
		if [regexp -nocase {UNITS\s+DISTANCE\s+MICRONS.*} $line] {
			append rv "$line\n"
			}
		if [regexp -nocase {^ROW.*\;} $line] { 
			append rv "$line\n"
			}
		}
	close $f
	return $rv
	}

proc scan_cell_class { class fn } {
	#puts -nonewline "Scanning '$fn' for '$class' cells .."
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
	#if [llength $rv] {
	#	puts "found [llength $rv] cells"
	#	} else {
	#		puts "not found"
	#		}
	return $rv
	}

proc symlink { fl dir } {
	foreach fn $fl {
		if { ! [file exists $fn] } {
			puts "File does not exist: '$fn'"
			exit 1
			}
		exec ln -sf $fn $dir/[file tail $fn]
		}
	}

proc find_and_symlink { path wildcard target } {
	catch {exec find $path -name $wildcard} lst
	symlink $lst $target
	}

proc make_PDN_link_folder { folder } {
	if { [file isdir $folder] && [string length $folder] > 5 } {
		puts "removing $folder"	
		}
	global design_root
	set design_root [file dir [file dir $::def_output]]
	puts "Creating design folder '$folder' from '$design_root'"
	foreach key {lef def verilog sdc pins lib doc scripts} {
		global env
		set dir $env(HOME)/work/designs/$folder/$key
		exec mkdir -p $dir
		case $key {
			scripts {
				set cdn [open $dir/pre-place.tcl w]
				set L $env(HOME)/work/designs/$folder/lef
				set V $env(HOME)/work/designs/$folder/verilog
				set D $env(HOME)/work/designs/$folder/def
				set clefs [glob $L/*tech*.lef]
				if { ! [regexp {([^_]+).*} [file tail $clefs] -> technology] } {
					puts "Could not identify technology name in '$clefs'"
					exit 3
					}
				# puts "# innovus -cpus 8 -file scripts/pre-place.tcl"
				puts $cdn "proc quit { } { exit }"
				puts $cdn "setMultiCpuUsage -localCpu 8"
				puts $cdn "setDesignMode -process 16"
				puts $cdn "setLibraryUnit -cap 1fF -time 1ps"
				set clefs [glob "$L/*tech*.lef" "$L/${technology}*base*.lef" "$L/tsmc*.lef"]
				puts $cdn "set init_gnd_net VSS\nset init_pwr_net VDD"
				puts $cdn "set init_lef_file {$clefs}"
				puts $cdn "set init_verilog [glob $V/*.v]"
				puts $cdn "init_design"
				close $cdn

				# Copy well-taps inserter
				global argv0
				exec ln -sf [file normalize [file dir $argv0]]/innovus_endcap.tcl $dir/
				}
			doc {
				global cellLef
				set lef1 [file dir [ file dir [lindex $::cellLef 0]] ]
				find_and_symlink $lef1 "*databook.pdf" $dir
				#find_and_symlink $lef1 "*userguide.pdf" $dir
				symlink /home/zf4_techdata/arm_nda/libraries/arm/tsmc/cln16fcll001/platform_userguide/r2p0/doc/sc_cln16fcll001_doc_userguide.pdf $dir
				}
			lef {
				global cellLef techLef flatLef
				symlink $::cellLef $dir
				symlink $::techLef $dir
				symlink $::flatLef $dir
				}
			def { # Create Innovus run sessions
				global def_output
				foreach fn [glob $design_root/*_post_T8_*.def] {
					if [regexp {.*_post_T8_([0-9]+)\.def} $fn -> runnum] {
						set targetdir [file normalize $dir/../run/$runnum]
						exec mkdir -p $targetdir
						#puts $targetdir
						symlink $fn $targetdir
						}
					}	
				symlink $::def_output $dir
				}
			verilog {
				global verilog
				symlink $::verilog $dir
				}
			sdc {
				global sdc
				symlink $::sdc $dir
				}
			pins {
				global pinLocationFile
				symlink $::pinLocationFile $dir
				}
			lib {
				global libraryFiles
				symlink $::libraryFiles $dir
				}
			}
		}
	# Symlink lef files
	}

proc setup_multiset_3rdparty_flow { {folder ""} } {
	set welltaps {}
	set endcaps {}
	global cellLef
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
	if { $folder == "" } {
		puts "Welltaps: $welltaps"
		puts "Endcaps: $endcaps"
		} else {
			global env
			set workdir $env(HOME)/work/designs/$folder
			set runall $workdir/runall.sh
			set t [open $runall w]
			set lef ../../lef/sc9mcpp96c_cln16fcll001_base_lvt_c16.lef
			set def "*_T8_*.def"
			set tapDef openroad_tapcell.def
			puts $t "cd $workdir"
			puts $t "for i in run/*;\ndo\n\tcd \$i\n\techo Running in `pwd`\n\tcp -f $def $tapDef"
			puts $t "\tchmod +w $tapDef"
			puts $t "\ttapcell -lef $lef -def $def -outdef $tapDef"
			puts $t "\tinnovus -batch -no_gui -cpus 8 -files ../../flow.tcl"
			puts $t "\tcd $workdir"
			puts $t "done"
			close $t
			exec chmod +x $runall
			# Verification script
			set cfg [open $workdir/flow.tcl w]
			global ::def_output
			puts $cfg "# Imported from [file dir [file dir $::def_output]]"
			puts $cfg "set design $folder"
			puts $cfg "set welltaps $welltaps"
			puts $cfg "set endcaps $endcaps"
			puts $cfg "source $workdir/scripts/pre-place.tcl"
			# Assuming to run from run/<NUM>/ where set def file is present
			#puts $cfg {defIn [glob *_post_*.def]}
			#puts $cfg "unplaceAllInst"
			puts $cfg "# Place endcaps with 3rd party source $workdir/scripts/innovus_endcap.tcl"
			puts $cfg "defIn $tapDef"
			puts $cfg "# Tapcell verification flow"
			close $cfg
		}
	}

################################################################################
#
# LEF/DEF custom parsing
# 
################################################################################

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

################################################################################
#
# C++ algorithmic interface
# 
################################################################################

# return name, block
proc get_all_blocks { key txt } {
	set flagOpen 0
	array set rv {}
	set name ""
	foreach line $txt {
		if { $flagOpen } {
			if [regexp "END\\\s+(\\\S+)" $line -> endname] {
				if { $endname == $name } {
					set flagOpen 0
					continue
					}
				}
			}
		if [regexp "$key\\\s+(\\\S+)\\\s*\$" $line -> name] {
			set flagOpen 1
			set rv($name) ""
			continue
			}
		if { $flagOpen } {
			lappend rv($name) [string trim $line]
			}
		}
	return [array get rv]
	}

proc create_site { name x y symmetry } {
	set placer [AbstractBridgeSwig_getPhysicalCellPlacer]
	#puts "site $name ($x,$y) x ($symmetry)"
	global Symmetry_X Symmetry_Y Symmetry_R90
	set var "Symmetry_$symmetry"
	AbstractBridgeSwig_createSite $placer $name $x $y [eval set $var]
	}

proc create_macro { name site ox oy x y sym} {
	set placer [AbstractBridgeSwig_getPhysicalCellPlacer]
	#puts "macro $name site $site ($ox $oy) ($x $y) '$sym'"
	global Symmetry_X Symmetry_Y Symmetry_R90
	symvector v
	foreach s [split $sym] {
		set var "Symmetry_$s"
		v push [eval set $var]		
		}
	AbstractBridgeSwig_createMacro $placer $name $site $ox $oy $x $y v
	}
	
proc create_fixed_inst { name macro x y ori } {
	#puts "create_fixed_inst { $name $macro $x $y $ori } "
	set placer [AbstractBridgeSwig_getPhysicalCellPlacer]
	global Orientation_N Orientation_FN Orientation_FS Orientation_S 
	global Orientation_W Orientation_FW Orientation_FE Orientation_E
	set var "Orientation_$ori"
	AbstractBridgeSwig_createInst $placer $name $macro $x $y [eval set $var]
	}
	
proc create_row {row site origX origY ori numX numY stepX stepY} {
	set placer [AbstractBridgeSwig_getPhysicalCellPlacer]
	#puts "-->> $row $site $origX $origY $ori $numX $numY $stepX $stepY"
	global Orientation_N Orientation_FN Orientation_FS Orientation_S 
	global Orientation_W Orientation_FW Orientation_FE Orientation_E
	set var "Orientation_$ori"
	AbstractBridgeSwig_createRow $placer \
		$row $site $origX $origY [eval set $var] $numX $numY $stepX $stepY
	}

#
# Load sites
#
proc load_sites { lefdef } {
	foreach {site desc} [get_all_blocks SITE $lefdef ] {
		set x 0
		set y 0
		set sym ""
		foreach rec $desc {
			if {  ! [regexp {SIZE\s+(\S+)\s+BY\s+(\S+)} $rec -> x y] } {
				if [regexp {SYMMETRY\s+([^\;]+)} $rec -> sym] {
					create_site $site $x $y [string trim $sym]
					break
					}
				}
			}
		}
	}
	
#
# Load macros
#

proc load_macro { lefdef } {
	
	foreach {macro desc} [get_all_blocks MACRO $lefdef ] {
		set x ""
		set y ""
		set ox 0
		set oy 0
		set sym ""
		set site ""
		foreach rec $desc {
			regexp {SIZE\s+(\S+)\s+BY\s+(\S+)} $rec -> x y
			regexp {ORIGIN\s+(\S+)\s+(\S+)} $rec -> ox oy
			regexp {SITE\s+(\S+)} $rec -> site
			regexp {SYMMETRY\s+([^\;]+)} $rec -> sym
			}
		create_macro $macro $site $ox $oy $x $y [string trim $sym]
		}
	}
	
#
# Load rows
#

proc load_rows { lefdef } {
	# ROW ROW_2484 sc9mcpp96c_cln16fcll001 1367808 540288 
	#   N DO 219 BY 1 STEP 192 0 ;
	set has_rows 0
	foreach line $lefdef {
		foreach {line row site origX origY ori numX numY stepX stepY } \
			[regexp -inline -nocase \
				{^ROW\s+(\S+)\s+(\S+)\s+([0-9]+)\s+([0-9]+)\s+(\S+)\s+DO\s+([0-9]+)\s+BY\s+([0-9]+)\s+STEP\s+([0-9]+)\s+([0-9]+)\s*[\;]*$} \
				$line] {
			create_row $row $site $origX $origY $ori $numX $numY $stepX $stepY
			set has_rows 1
			}
		}
	if { ! $has_rows } {
		puts "Could not find any placement rows"
		exit 1
		}
	}

#
# Associate macro types
#
proc set_macro { type cell } {
	set placer [AbstractBridgeSwig_getPhysicalCellPlacer]
	global TIETYPE_TOP_OR_BOTTOM_NWELL_INSIDE TIETYPE_CAP_NWELL_INSIDE \
					TIETYPE_FILL TIETYPE_CAP_NWELL_OUTSIDE \
					TIETYPE_TOP_OR_BOTTOM_NWELL_OUTSIDE TIETYPE_ENDCAP
	$placer macro_config [eval set "TIETYPE_${type}"] "${cell}"
	}

#
# Orientation DEF code for C++ symbol / numeric code
#

proc oriCode { x } {
	global Orientation_N Orientation_FS Orientation_S Orientation_FN
	if { $x == $::Orientation_N } { return N }
	if { $x == $::Orientation_FS } { return FS } 
	if { $x == $::Orientation_S } { return S }
	if { $x == $::Orientation_FN } { return FN }
	puts "Wrong orientation code '$x'"
	exit 1
	}
	

#
# Return Tcl-friendly result for post-processing and export to DEF
#

proc run_physical_cell_placement { } {
	
	set placer [AbstractBridgeSwig_getPhysicalCellPlacer]

	array set rv {}
		
	set v [AbstractBridgeSwig_place $placer]
	
	set keys [get_keys $v]
	
	if { 0 == [llength $keys] } {
		puts stderr "Physical cell placement failed"
		exit 1
		}
	
	foreach macro [get_keys $v] {
		set pv [result_get $v $macro]
		#puts "$macro ([get_plc_size $pv] cells):"
		for { set i 0 } { $i < [get_plc_size $pv] } { incr i } {
			set plc [plcvector_get $pv $i]
			lassign [list [Placement_x_get $plc] [Placement_y_get $plc] \
				[Placement_ori_get $plc]] Px Py Pori
			lappend rv($macro) \
				[list [expr round($Px)] [expr round($Py)] [oriCode $Pori] ]
			$plc -delete
			}
		}
	return [array get rv]
	}
	
#
# Well tap checkerboard spacing
#

proc set_checkerbooard { spacing_um } {
	set placer [AbstractBridgeSwig_getPhysicalCellPlacer]
	AbstractBridgeSwig_checkerboard_distance $placer $spacing_um
	}
	
#
# Grab units from def
#
proc set_units_per_micron { lefdef } {
	# UNITS DISTANCE MICRONS 2000 ;
	set placer [AbstractBridgeSwig_getPhysicalCellPlacer]
	foreach line $lefdef {
		if [regexp {UNITS\s+DISTANCE\s+MICRONS\s+([0-9]+)} $line -> dbunits_per_micron] {
			break
			}
		}
	
	if { ! [info exists dbunits_per_micron] } {
		puts "DEF does not have db units"
		exit 2
		}
	
	#puts "Read DEF setting: $dbunits_per_micron db units per um "
	AbstractBridgeSwig_db_units $placer $dbunits_per_micron
	}
	
#
# Replace row definitions 
#
proc replace_rows_section { def } {
	
	set placer [AbstractBridgeSwig_getPhysicalCellPlacer]
	set rows [AbstractBridgeSwig_rows $placer]

	set nr [get_num_rows $rows]
	
	set rows_def {}
	for { set i 0 } { $i < $nr } { incr i } {
		set row [rowvector_get $rows $i]
		set srow  "ROW [$row cget -name] [$row cget -site] "
		append srow "[expr round([$row cget -orig_x])] \
			[expr round([$row cget -orig_y])] "
		append srow [oriCode [$row cget -ori]]
		append srow " DO [$row cget -num_x] BY [$row cget -num_y] "
		append srow "STEP [$row cget -step_x] [$row cget -step_y] ;"
		lappend rows_def $srow
		}
	unset rows
	
	set rv {}
	foreach line $def {
		if { ! [regexp -nocase {ROW\s+\S+.*} $line] } { 
			lappend rv $line
			} else {
				if [info exists rows_def] {
					foreach r $rows_def {
						lappend rv $r
						}
					unset rows_def
					}
				}
		}
	return $rv
	}
	
#
# Remove placed components from DEF
# Remove all components matching physical cell pattern
# Add extra placed DEF cells into DEF file
#

proc replace_placement_section { expendables def extraCount extraDef } {
	set rv ""
	set components_done 0
	set components_open 0
	set COMPONENTS ""
	set cnt 0
	
	foreach line $def {
		if { $components_done } {
			append rv "${line}\n"
			continue
			}
		if { $components_open } {
			if [regexp -nocase {END\s+COMPONENTS} $line] {
				set components_open 0
				append rv "COMPONENTS [expr $cnt + $extraCount] ;\n"
				append rv "${COMPONENTS}${extraDef}"
				append rv "END COMPONENTS\n"
				} else { 
					# Get macro name and placement status
					if { ! [regexp {\-\s+\S+\s+(\S+)\s+\S+\s+(\S+)} $line -> \
						macro status] } {
							append COMPONENTS "${line}\n"
							incr cnt
							continue
							}
					# is it a FIXED element?
					if [regexp -nocase -- {^FIXED$} $status] {
						append COMPONENTS "${line}\n"
						incr cnt
						continue
						}
					if [regexp -nocase -- {^PLACED$} $status] {
						# dropping placed components, no legalizer enabled
						continue
						}
					# is it expandable?
					foreach m $expendables {
						if [regexp $m $macro ] {
							# Remove previously placed physical cells
							continue
							}
						}
					}
			continue
			}
		if [regexp -nocase {COMPONENTS\s+[0-9]+} $line] {
			set components_open 1
			} else {
				set line [string trim $line]
				if [string length $line] {
					append rv "${line}\n"
					}
				}
		}
	return $rv
	}

#
# Load fixed cells and break rows underneath
#

proc load_fixed_cells { def expendables } {
	set components_open 0
	foreach line $def {
		if $components_open { 
				if [regexp -nocase {END\s+COMPONENTS} $line] {
					# End of processing
					break
					}
				# Get macro name and placement status
				if { ! [regexp -nocase {\-\s+(\S+)\s+(\S+)\s*\+\s*FIXED\s*\(\s*([0-9]+)\s+([0-9]+)\s*\)\s*(\S+)} $line -> \
					name macro x y ori] } {
						continue
						}
				# is it expandable?
				foreach m $expendables {
					if [regexp $m $macro ] {
						# Remove previously placed physical cells
						continue
						}
					}
				create_fixed_inst $name $macro $x $y $ori
			} else {
				if [regexp -nocase {COMPONENTS\s+[0-9]+} $line] {
					set components_open 1
					}
			}
		}
	}

#
# Remove empty lines
# Glue all lines with ';' to the previous line
#
proc glue_semicolumn { raw } {
	# Some vendors require space before ;
	regsub -all {\s+\;} $raw " ;" rv
	return $rv
	}

#
# If resulting DEF file exists, update it
# Otherwise, create it
# 
# Arguments:
#   def - formatted physical cell DEF text
#   out_def - resulting file
#   cnt - number of cells in physical cell DEF text
#
proc create_or_update_def { out_def cnt def cells } {
	
	if { [file exist $out_def] && [file size $out_def] } {
		# Replacing components section in existing DEF
		set f [open $out_def r]
		set def_raw [split [glue_semicolumn [read $f]] "\n"]
		close $f
		set f [open $out_def w]
		
		# In case if weant to dump cut sections, make it an option
		global flagUpdateRowsDefinition
		if { $flagUpdateRowsDefinition } {
			puts {Updating rows defintions}
			set def_raw [replace_rows_section $def_raw]
			}
		
		# That will remove all placed components and cells matching the list
		puts $f [replace_placement_section \
			$cells $def_raw $cnt $def]
		close $f
	
		} else {
			# Creating DEF with components section
			set f [open $out_def w]
			puts $f "COMPONENTS $cnt;"
			puts $f $def
			unset def
			puts $f "END COMPONENTS"
			close $f
			}
	}

proc default_flow { lef_files def out_def } {

# Load LEF
################################################################################

foreach lef [split $lef_files] {
	puts "Loading '$lef' .."
	set f [open $lef r]
	foreach l [split [read $f] "\n"] {
		lappend lef_raw $l
		}
	close $f
	}
load_sites $lef_raw
load_macro $lef_raw
unset lef_raw

# Configure placer
################################################################################
puts {Configuring placement engine}
global tieCfg PHYSICAL_CELLS
array set config $tieCfg
if { ! [info exists config(welltap)] } {
	puts "Please specify welltap macro name"
	exit 105
	}
if { ! [info exists config(endcap)] } {
	puts "Please specify encdap macro name"
	exit 106
	}
if { ! [info exists config(rule)] } {
	puts "Please specify checkerboard distance"
	exit 105
	}
set PHYSICAL_CELLS [list config(welltap) config(endcap)]
set_checkerbooard $config(rule)
set_macro ENDCAP $config(endcap)
set_macro FILL $config(welltap)

# Load DEF
################################################################################

puts "Loading '$def' .."
set f [open $def r]
set def_raw [split [read $f] "\n"]
close $f

set_units_per_micron $def_raw
load_rows $def_raw
global PHYSICAL_CELLS
load_fixed_cells $def_raw $PHYSICAL_CELLS
unset def_raw

# Run placement
################################################################################

puts {Running physical cell placement}
array set placement [run_physical_cell_placement]
set cnt 0
set def ""
foreach macro [array names placement] {
	foreach val $placement($macro) {
		lassign $val x y ori
		set prefix "PHY_"
		array set mcnt {}
		if [regexp {ENDCAP.*} $macro ] {
			set prefix "ENDCAP_"
			} else {
				if [regexp {FILLTIE.*} $macro ] {
					set prefix "WELLTAP_"
					}
				}
		incr mcnt($prefix)
		append def "- $prefix$mcnt($prefix) $macro  + SOURCE DIST  + FIXED ( $x $y ) $ori ;\n"
		}
	}
puts {Placement completed}

# Save resulting DEF placement file
################################################################################

puts "Writing resulted physical cell placement into '$out_def'"

create_or_update_def $out_def $cnt $def $PHYSICAL_CELLS
puts {Done}
exit 0
# end of default flow
}
