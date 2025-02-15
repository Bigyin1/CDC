
build:
	iverilog -g2005-sv fifo.sv gray.sv cdc.sv tb.sv
	vvp a.out
