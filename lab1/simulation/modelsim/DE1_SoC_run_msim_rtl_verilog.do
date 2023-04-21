transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Downloads/ee469\ lab1 {C:/Users/Aaron Hong/Downloads/ee469 lab1/fulladder32.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Downloads/ee469\ lab1 {C:/Users/Aaron Hong/Downloads/ee469 lab1/fulladder.sv}
vlog -sv -work work +incdir+C:/Users/Aaron\ Hong/Downloads/ee469\ lab1 {C:/Users/Aaron Hong/Downloads/ee469 lab1/alu.sv}

