
build:
	iverilog -g2005-sv fifo.sv gray.sv cdc.sv test/test_pkg.sv test/tb.sv
	vvp a.out
