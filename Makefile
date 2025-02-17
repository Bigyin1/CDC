
build:
	verilator  fifo.sv gray.sv cdc.sv tb.sv  --timing --trace  --trace-structs  --binary --top AXI_Bridge_TB
	vvp a.out
