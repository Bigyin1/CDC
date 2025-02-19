
build:
	verilator  fifo.sv gray.sv cdc.sv tb.sv --trace --trace-structs  --timing  --assert --no-stop-fail --binary --top AXI_Bridge_TB -CFLAGS -std=c++20 
	# obj_dir/VAXI_Bridge_TB
