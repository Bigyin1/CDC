module AXI_Bridge_TB ();

  parameter PRIMARY_CLK_DELAY = 2;
  parameter SECONDARY_CLK_DELAY = 19;

  logic p_rst = 1'b1;
  logic p_clk = 1'b0;

  logic s_rst = 1'b1;
  logic s_clk = 1'b0;

  always #(PRIMARY_CLK_DELAY) p_clk = ~p_clk;
  always #(SECONDARY_CLK_DELAY) s_clk = ~s_clk;


  logic [1:0] cfg;

  logic [63:0] p_axis_data;
  logic p_axis_valid;
  logic p_axis_last;
  logic p_axis_ready;

  logic [31:0] s_axis_data;
  logic s_axis_valid;
  logic s_axis_last;
  logic s_axis_ready;

  axi_cdc #(
      .WIDTH_P(64),
      .WIDTH_S(32)
  ) u_axi_cdc (
      .clk_p(p_clk),
      .clk_s(s_clk),
      .rst_p(p_rst),
      .rst_s(s_rst),

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


  initial begin

    $dumpfile("dump.vcd");
    $dumpvars;

    p_axis_valid = 0;

    #(2);
    p_rst = 0;
    s_rst = 0;
    #(2);
    p_rst = 1;
    s_rst = 1;


    for (int i = 0; i < 16; ++i) begin
      @(posedge p_clk);

      if (p_axis_ready) begin
        p_axis_data  <= $random;
        p_axis_valid <= 1;
        if (i == 15) p_axis_last <= 1;
        else p_axis_last <= 0;

        cfg <= 0;
      end else begin
        @(posedge p_axis_ready);
      end

    end



  end


  initial begin

    @(posedge s_clk);
    s_axis_ready <= 1;

    @(posedge s_clk);
    @(posedge s_clk);

    @(posedge s_axis_last);

    $finish;
  end

endmodule
