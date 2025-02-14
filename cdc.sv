

module sync (
    input wire clk,
    input wire rst,

    input  wire i_ctrl,
    output wire o_ctrl
);

  logic [1:0] sync_r;
  always_ff @(posedge clk) begin
    if (rst) 
        sync_r <= 0;
    else 
        sync_r <= {sync_r[0], i_ctrl};
    
  end

  assign o_ctrl = sync_r[1];

endmodule



module axi_cdc #(
    parameter WIDTH_P = 64,
    WIDTH_S = 32
) (
    input wire clk_p,
    input wire clk_s,

    input wire [1:0] cfg,

    input  wire [WIDTH_P-1] p_axis_data,
    input  wire             p_axis_valid,
    input  wire             p_axis_last,
    output wire             p_axis_ready,


    output wire [WIDTH_S-1] s_axis_data,
    output wire             s_axis_valid,
    output wire             s_axis_last,
    input  wire             s_axis_ready

);




endmodule
