transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/top.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/reg_file.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/fulladder32.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/fulladder.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/dmem.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/arm.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/alu.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/cond_unit.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/hazard_unit.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Documents/cse469/lab3 {C:/Users/Aaron Hong/Documents/cse469/lab3/imem.sv}

