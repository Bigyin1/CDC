class Packet #(parameter DATA_WIDTH);
    rand bit[DATA_WIDTH-1:0]    data;
    rand bit                    last;

    rand bit[1:0]               cfg;
endclass
