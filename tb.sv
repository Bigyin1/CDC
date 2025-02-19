module AXI_Bridge_TB ();

  import test_pkg::*;

  import axi_cdc_config::*;

  localparam PRIMARY_CLK_DELAY = 1;
  localparam SECONDARY_CLK_DELAY = 23;

  logic clk_p = 0;
  logic rst_p;

  logic clk_s = 0;
  logic rst_s;


  axis_intf_p #(WIDTH_P) intf_master (clk_p, rst_p);
  axis_intf_s #(WIDTH_S) intf_slave  (clk_s, rst_s);


  axi_cdc #(
      .FIFO_DEPTH(FIFO_DEPTH)
  ) DUT (
      .clk_p(clk_p),
      .rst_p(rst_p),
      .clk_s(clk_s),
      .rst_s(rst_s),

      .cfg(intf_master.cfg),

      .p_axis_data (intf_master.data),
      .p_axis_valid(intf_master.valid),
      .p_axis_last (intf_master.last),
      .p_axis_ready(intf_master.ready),

      .s_axis_data (intf_slave.data),
      .s_axis_valid(intf_slave.valid),
      .s_axis_last (intf_slave.last),
      .s_axis_ready(intf_slave.ready)
  );


  task reset_primary();
        rst_p <= 0;
        #(2);
        rst_p <= 1;
  endtask

  task reset_secondary();
        rst_s <= 0;
        #(2);
        rst_s <= 1;
  endtask


  always #(PRIMARY_CLK_DELAY) clk_p = ~clk_p;
  
  always #(SECONDARY_CLK_DELAY) clk_s = ~clk_s;


  always begin
    Test #(WIDTH_P, WIDTH_S) t = null;
    
    for (int i=0; i<30; ++i) begin
      
      t = new(intf_master, intf_slave);

      t.gen_testdata();

      fork
        reset_primary();
        reset_secondary();
      join

      fork
        t.primary();
        t.secondary();
      join

      t.check();
    end

    #200
    $finish;
  end


  initial begin

    $dumpfile("dump.vcd");
    $dumpvars;
  
   #400000

    $error("Timeout");
    $finish;
  end

endmodule
