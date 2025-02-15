

module gray_counter #(
    parameter SIZE = 4
) (
    input clk,
    input n_rst,
    input inc,

    output [  SIZE:0] gray_cnt,
    output [SIZE-1:0] bin_cnt
);

  reg [SIZE:0] rbin;
  reg [SIZE:0] rgray;

  assign bin_cnt  = rbin[SIZE-1:0];
  assign gray_cnt = rgray;

  wire [SIZE:0] rgray_next, rbin_next;

  assign rbin_next  = rbin + inc;

  assign rgray_next = (rbin_next >> 1) ^ rbin_next;

  always @(posedge clk or negedge n_rst)
    if (!n_rst) {rbin, rgray} <= 0;
    else {rbin, rgray} <= {rbin_next, rgray_next};

endmodule
