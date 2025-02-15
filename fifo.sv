module sync #(
    parameter SIZE = 4
) (
    input clk,
    input n_rst,

    input  [SIZE-1:0] i_ctrl,
    output [SIZE-1:0] o_ctrl
);

  logic [SIZE-1:0] sync_r1;
  logic [SIZE-1:0] sync_r2;

  always_ff @(posedge clk or negedge n_rst) begin
    if (!n_rst)
        {sync_r2, sync_r1} <= 0;
    else
        {sync_r2, sync_r1} <= {sync_r1, i_ctrl};

  end

  assign o_ctrl = sync_r2;

endmodule


module fifo_async #(
    parameter WIDTH = 32,
    parameter DEPTH = 8
) (
    input              w_clk,
    input              w_rst,
    input  [WIDTH-1:0] w_data,
    input              push,
    output             w_full,

    input              r_clk,
    input              r_rst,
    output [WIDTH-1:0] r_data,
    input              pop,
    output             r_empty
);

  localparam ADDRSIZE = $clog2(DEPTH);


  logic [  ADDRSIZE:0] r_gray;
  logic [ADDRSIZE-1:0] r_memaddr;

  gray_counter #(
      .SIZE(ADDRSIZE)
  ) r_counter (
      .clk  (r_clk),
      .n_rst(r_rst),
      .inc  (pop & !r_empty),

      .gray_cnt(r_gray),
      .bin_cnt (r_memaddr)
  );


  logic [  ADDRSIZE:0] w_gray;
  logic [ADDRSIZE-1:0] w_memaddr;

  gray_counter #(
      .SIZE(ADDRSIZE)
  ) w_counter (
      .clk  (w_clk),
      .n_rst(w_rst),
      .inc  (push & !w_full),

      .gray_cnt(w_gray),
      .bin_cnt (w_memaddr)
  );


  logic [ADDRSIZE:0] sync_w_gray;
  logic [ADDRSIZE:0] sync_r_gray;

  sync #(
      .SIZE(ADDRSIZE + 1)
  ) sync_w2r (
      .clk(r_clk),
      .n_rst(r_rst),

      .i_ctrl(w_gray),
      .o_ctrl(sync_w_gray)
  );

  sync #(
      .SIZE(ADDRSIZE + 1)
  ) sync_r2w (
      .clk(w_clk),
      .n_rst(w_rst),

      .i_ctrl(r_gray),
      .o_ctrl(sync_r_gray)
  );

  assign r_empty = (sync_w_gray == r_gray);

  assign w_full = ( (w_gray[ADDRSIZE]       !=  sync_r_gray[ADDRSIZE] ) &&
                    (w_gray[ADDRSIZE-1]     !=  sync_r_gray[ADDRSIZE-1]) &&
                    (w_gray[ADDRSIZE-2:0]   ==  sync_r_gray[ADDRSIZE-2:0]) );


  logic [WIDTH - 1:0] data[0:DEPTH - 1];

  always_ff @(posedge w_clk)
    if (push & !w_full)
        data[w_memaddr] <= w_data;

  assign r_data = data[r_memaddr];


endmodule
