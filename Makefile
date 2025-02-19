
build:
	verilator  ./axi_cdc/*.sv ./test/intf.sv ./test/test_pkg.sv tb.sv --trace --trace-structs  --timing  --assert --no-stop-fail --binary --top AXI_Bridge_TB -CFLAGS -std=c++20 
	# obj_dir/VAXI_Bridge_TB
