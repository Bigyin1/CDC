interface axis_intf_p #(parameter DATA_WIDTH)
    (input logic clk, input logic n_rst);

    logic                   valid;
    logic                   ready;
    logic [DATA_WIDTH-1:0]  data;
    logic                   last;

    logic [1:0]             cfg;

endinterface

interface axis_intf_s #(parameter DATA_WIDTH)
    (input logic clk, input logic n_rst);

    logic                   valid;
    logic                   ready;
    logic [DATA_WIDTH-1:0]  data;
    logic                   last;

endinterface
