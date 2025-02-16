

module testbench;

    import test_pkg::*;

    logic        clk_p;
    logic        nrst_p;
    logic        clk_s;
    logic        nrst_s;

    axis_intf intf_master (clk_p, nrst_p);
    axis_intf intf_slave  (clk_s, nrst_s);


    //---------------------------------
    // Модуль для тестирования
    //---------------------------------


    axi_cdc #(
        .WIDTH_P(64),
        .WIDTH_S(32),
        .FIFO_DEPTH(8)
    ) DUT (
        .clk_p(clk_p),
        .rst_p(rst_p),
        .clk_s(clk_s),
        .rst_s(rst_s),

        .cfg(intf_master.cfg),

        .p_axis_data (intf_master.tdata),
        .p_axis_valid(intf_master.valid),
        .p_axis_last (intf_master.tlast),
        .p_axis_ready(intf_master.tready),

        .s_axis_data (intf_slave.tdata),
        .s_axis_valid(intf_slave.tvalid),
        .s_axis_last (intf_slave.tlast),
        .s_axis_ready(intf_slave.tready)
    );


    //---------------------------------
    // Переменные тестирования
    //---------------------------------

    // Период тактового сигнала
    parameter PRIMARY_CLK_DELAY = 2;
    parameter SECONDARY_CLK_DELAY = 19;


    //---------------------------------
    // Общие методы
    //---------------------------------

    // Генерация сигнала сброса
    task reset_master();
        nrst_p <= 0;
        #(2*PRIMARY_CLK_DELAY);
        nrst_p <= 1;
    endtask

    task reset_slave();
        nrst_s <= 0;
        #(2*SECONDARY_CLK_DELAY);
        nrst_s <= 1;
    endtask


    //---------------------------------
    // Выполнение
    //---------------------------------

    // Генерация тактового сигнала
    initial begin
        clk_p <= 0;
        forever begin
            #(PRIMARY_CLK_DELAY) clk_p <= ~clk_p;
        end
    end

    initial begin
        clk_s <= 0;
        forever begin
            #(SECONDARY_CLK_DELAY) clk_s <= ~clk_s;
        end
    end

    initial begin
        test_base test;
        test = new(intf_master, intf_slave);
        fork
            reset();
            test.run();
        join_none
        repeat(1000) @(posedge clk);
        // Сброс в середине теста
        reset();
    end

endmodule
