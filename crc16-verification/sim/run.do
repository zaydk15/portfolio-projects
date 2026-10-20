# run.do - QuestaSim script (Linux)
vdel -all
vlib work

# DUT
vlog ../dut/crc16.sv
vlog ../dut/crc16_top.sv

# TB packages & top
vlog ../tb/interface.sv
vlog ../tb/crc_ref.sv
vlog ../tb/crc_env_pkg.sv
vlog ../tb/test.sv

# Start simulation
vsim test

add wave -r *

run -all

