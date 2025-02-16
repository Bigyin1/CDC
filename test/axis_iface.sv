interface axis_intf #(
    parameter DATA_WIDTH
) (input logic clk, input logic nrst);

    logic                   tvalid;
    logic                   tready;
    logic [DATA_WIDTH-1:0]  tdata;
    logic                   tlast;

    logic [1:0]             cfg;

    logic        tid;


    property pTvalidStable;
        @(posedge clk) tvalid & ~tready |-> ##1 tvalid; 
    endproperty

    apTvalidStable: assert property(pTvalidStable) begin
        $display("Good at time %0d", $time());
        $stop();
    end
    else begin
        $display("Bad at time %0d", $time());
        $stop();
    end


endinterface
