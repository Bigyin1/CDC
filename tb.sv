interface axis_intf_p(input logic clk, input logic n_rst);

     logic       valid;
     logic       ready;
     logic [64-1:0] data;
     logic        last;

     logic [1:0]  cfg;

     modport DUT (
        input        valid,
        output        ready,
        input   data,
        input         last,

        input   cfg

     );

  endinterface

  interface axis_intf_s(input logic clk, input logic n_rst);

     logic       valid;
     logic       ready;
     logic [32-1:0] data;
     logic        last;

  endinterface



module AXI_Bridge_TB ();

  localparam PRIMARY_CLK_DELAY = 13;
  localparam SECONDARY_CLK_DELAY = 3;

  localparam FIFO_DEPTH = 32; // pow 2

  logic clk_p = 0;
  logic rst_p;

  logic clk_s = 0;
  logic rst_s;


  axis_intf_p intf_master(clk_p, rst_p);
  axis_intf_s intf_slave(clk_s, rst_s);


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

      .cfg(intf_master.DUT.cfg),

      .p_axis_data (intf_master.DUT.data),
      .p_axis_valid(intf_master.DUT.valid),
      .p_axis_last (intf_master.DUT.last),
      .p_axis_ready(intf_master.DUT.ready),

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



  class Packet;
    rand bit[64-1:0] data;
    rand bit         last;

    rand bit[1:0]    cfg;
  endclass


  typedef Packet Packet_queue[$];

  class Test;
    Packet_queue slave_queue ;
    Packet_queue master_queue ;

    virtual axis_intf_p.DUT intf_master;
    virtual axis_intf_s intf_slave;

    int amount = 0;

    function  new(
      virtual axis_intf_p.DUT mi,
      virtual axis_intf_s si,
    );

      this.intf_master = mi;
      this.intf_slave = si;
      
    endfunction
  
    function void gen_testdata();

      for (int i=0; i < $urandom_range(11, 134); ++i) begin
        Packet pk = new();

        /* verilator lint_off IGNOREDRETURN */
        pk.randomize();

        if (pk.cfg == 2'b00 || pk.cfg == 2'b01)
          this.amount += 1;
        else
          this.amount += 2;

        this.master_queue.push_back(pk);
      end
    endfunction


    task  primary();
      reset_primary();

      intf_master.valid <= 0;
      @(posedge intf_master.clk);


      foreach (this.master_queue[i]) begin
        
        // $display("%p", this.master_queue[i]);
        intf_master.valid <= 1;

        intf_master.data   <=  this.master_queue[i].data;
        intf_master.cfg    <=  this.master_queue[i].cfg;
        intf_master.last   <=  this.master_queue[i].last;

        do begin
            @(posedge intf_master.clk);
        end
        while(~intf_master.ready);
      end

      intf_master.valid <= 0;

    endtask

    task secondary();
      reset_secondary();

      intf_slave.ready <= 1;

      while(1) begin
        @(posedge intf_slave.clk);

        if (intf_slave.valid) begin
          Packet pack = new();

          pack.data = 64'(intf_slave.data);
          pack.last = intf_slave.last;

          this.slave_queue.push_back(pack);
          // $display("%p, %d", pack, slave_queue.size());

          if (this.slave_queue.size() == this.amount)
            break;

        end
      end

      intf_slave.ready <= 0;

    endtask

  function void checkEqualQueues();
    Packet m_pack, s_pack_1, s_pack_2;

      while (this.master_queue.size() != 0) begin
        m_pack = this.master_queue.pop_front();

        if (this.slave_queue.size() == 0) begin
          $error("Unexpected empty slave queue m_sz: %d", this.master_queue.size());
          break;
        end

        s_pack_1 = this.slave_queue.pop_front();
        
        case (m_pack.cfg)
          2'b00: begin
            if (s_pack_1.data[32-1:0] != m_pack.data[32-1:0])
              $error("data mismatch: exp: %0x , got: %0x", m_pack.data[32-1:0], s_pack_1.data);
            if (s_pack_1.last != m_pack.last)
              $error("expected last data; cycle: m_sz: %d, s_sz: %d", this.master_queue.size(), this.slave_queue.size());
          end

          2'b01: begin
            if (s_pack_1.data[32-1:0] != m_pack.data[64-1:32])
              $error("data mismatch: exp: %0x , got: %0x", m_pack.data[64-1:32], s_pack_1.data);
            if (s_pack_1.last != m_pack.last)
              $error("expected last data; cycle: m_sz: %d, s_sz: %d", this.master_queue.size(), this.slave_queue.size());
          end

          2'b10: begin
            if (this.slave_queue.size() == 0) begin
              $error("Unexpected empty slave queue");
              break;
            end
          
            s_pack_2 =  this.slave_queue.pop_front();

            if ({s_pack_2.data[32-1:0] ,s_pack_1.data[32-1:0]} != m_pack.data)
              $error("data mismatch: exp: %0x , got: %0x", m_pack.data, {s_pack_2.data[32-1:0] ,s_pack_1.data[32-1:0]});
            if (s_pack_2.last != m_pack.last)
              $error("expected last data; cycle: m_sz: %d, s_sz: %d", this.master_queue.size(), this.slave_queue.size());
          end

          2'b11: begin
            if (this.slave_queue.size() == 0) begin
              $error("Unexpected empty slave queue");
              break;
            end
          
            s_pack_2 = this.slave_queue.pop_front();

            if ({s_pack_1.data[32-1:0] ,s_pack_2.data[32-1:0]} != m_pack.data)
              $error("data mismatch: exp: %0x , got: %0x", m_pack.data, {s_pack_1.data[32-1:0] ,s_pack_2.data[32-1:0]});
            if (s_pack_2.last != m_pack.last)
              $error("expected last data; cycle: m_sz: %d, s_sz: %d", this.master_queue.size(), this.slave_queue.size());
          end

          default:
            begin end
        endcase
      end
    endfunction
  endclass


  always begin
    Test t;
    
    for (int i=0; i<45; ++i) begin
      
    
      t = new(intf_master, intf_slave);

      t.gen_testdata();

      fork
        t.primary();
        t.secondary();
      join

      t.checkEqualQueues();

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
