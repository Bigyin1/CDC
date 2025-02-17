module AXI_Bridge_TB ();

  localparam PRIMARY_CLK_DELAY = 3;
  localparam SECONDARY_CLK_DELAY = 33;

  localparam FIFO_DEPTH = 32; // pow 2

  logic clk_p;
  logic rst_p;

  logic clk_s;
  logic rst_s;


  logic [1:0] cfg;

  logic [64-1:0] p_axis_data;
  logic p_axis_valid;
  logic p_axis_last;
  logic p_axis_ready;

  logic [32-1:0] s_axis_data;
  logic s_axis_valid;
  logic s_axis_last;
  logic s_axis_ready;

  axi_cdc #(
      .FIFO_DEPTH(FIFO_DEPTH)
  ) DUT (
      .clk_p(clk_p),
      .rst_p(rst_p),
      .clk_s(clk_s),
      .rst_s(rst_s),

      .cfg(cfg),

      .p_axis_data (p_axis_data),
      .p_axis_valid(p_axis_valid),
      .p_axis_last (p_axis_last),
      .p_axis_ready(p_axis_ready),

      .s_axis_data (s_axis_data),
      .s_axis_valid(s_axis_valid),
      .s_axis_last (s_axis_last),
      .s_axis_ready(s_axis_ready)
  );


  task reset_primary();
        rst_p = 0;
        #(2);
        rst_p = 1;
  endtask

  task reset_secondary();
        rst_s = 0;
        #(2);
        rst_s = 1;
  endtask


  initial begin
      clk_p = 0;
      forever begin
          #(PRIMARY_CLK_DELAY) clk_p = ~clk_p;
      end
  end


  initial begin
      clk_s = 0;
      forever begin
          #(SECONDARY_CLK_DELAY) clk_s = ~clk_s;
      end
  end


  logic[64-1:0] dqueue [$];
  logic         lqueue [$];
  logic[1:0] cfgqueue [$];


  task primary(input int curr_cfg, input int cycles);

    reset_primary();

    p_axis_valid = 0;

    for (int i = 0; i < cycles; ++i) begin
      
      @(posedge clk_p);

      p_axis_data = {$random, $random};
      p_axis_valid = 1;

     
      cfg = 2'(curr_cfg);

      if (i == cycles - 1)
        p_axis_last = 1;
      else
        p_axis_last = 0;

      #(1)

      dqueue.push_back(p_axis_data);
      lqueue.push_back(p_axis_last);
      cfgqueue.push_back(cfg);

      if (!p_axis_ready)
        @(posedge p_axis_ready);

    end

    @(posedge clk_p);

    p_axis_valid = 0;

  endtask

  logic[32-1:0] s_dqueue [$];
  logic s_lqueue [$];

  task secondary(int cycles);

    reset_secondary();

    s_axis_ready = 1;

    for (int i=0; i<cycles; ++i) begin
    
      do begin
        @(posedge clk_s);

        #(1);
      end while (s_axis_valid != 1);

      s_dqueue.push_back(s_axis_data);
      s_lqueue.push_back(s_axis_last);

    end
  
    s_axis_ready = 0;
  endtask

  // task checkEqualQueues(port_list);
    
  // endtask



  initial begin
    localparam CYCL = 66;

    $dumpfile("dump.vcd");
    $dumpvars;


    fork
      primary('b00, CYCL);
      secondary(CYCL);
    join

    fork
      primary('b01, CYCL);
      secondary(CYCL);
    join

    fork
      primary('b10, CYCL);
      secondary(CYCL*2);
    join

    fork
      primary('b11, CYCL);
      secondary(CYCL*2);
    join

    // fork
    //   primary(-1, CYCL);
    //   secondary(CYCL);
    // join

    #400
    $finish;
  end

endmodule
