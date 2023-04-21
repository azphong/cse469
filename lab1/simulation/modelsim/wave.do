onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fullAdder_testbench/dut/A
add wave -noupdate /fullAdder_testbench/dut/B
add wave -noupdate /fullAdder_testbench/dut/cin
add wave -noupdate /fullAdder_testbench/dut/cout
add wave -noupdate /fullAdder_testbench/dut/sum
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {60 ps} 0} {{Cursor 2} {682 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 208
configure wave -valuecolwidth 147
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 100
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {86 ps}
