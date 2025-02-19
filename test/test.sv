
class Test #(parameter WIDTH_M = 64,
            parameter  WIDTH_S = 32);

    Packet #(WIDTH_M) master_queue[$];
    Packet #(WIDTH_S) slave_queue[$];

    virtual axis_intf_p #(WIDTH_M) intf_master;
    virtual axis_intf_s #(WIDTH_S) intf_slave;

    int exp_packs_amount = 0;

    function new(
      virtual axis_intf_p #(WIDTH_M) mi,
      virtual axis_intf_s #(WIDTH_S) si,
    );
      this.intf_master = mi;
      this.intf_slave = si;
    endfunction
  
    function void gen_testdata();

      for (int i=0; i < $urandom_range(11, 134); ++i) begin
        Packet #(WIDTH_M) pk = new();

        /* verilator lint_off IGNOREDRETURN */
        pk.randomize();

        if (pk.cfg == 2'b00 || pk.cfg == 2'b01)
          this.exp_packs_amount += 1;
        else
          this.exp_packs_amount += 2;

        this.master_queue.push_back(pk);
      end
    endfunction


    task primary();

      intf_master.valid <= 0;

      @(posedge intf_master.clk);

      foreach (this.master_queue[i]) begin
    
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

      intf_slave.ready <= 1;

      while(this.slave_queue.size() != this.exp_packs_amount) begin

        @(posedge intf_slave.clk);

        if (intf_slave.valid) begin
          Packet #(WIDTH_S) pack = new();

          pack.data = intf_slave.data;
          pack.last = intf_slave.last;

          this.slave_queue.push_back(pack);
          // $display("%p, %d", pack, slave_queue.size());

        end
      end

      intf_slave.ready <= 0;
    endtask


    local function Packet #(WIDTH_S) check_single(Packet #(WIDTH_M) m_pack);
        
        Packet #(WIDTH_S) s_pack_1 = this.slave_queue.pop_front();

        case (m_pack.cfg)

            2'b00:
                if (s_pack_1.data != m_pack.data[WIDTH_S-1:0])
                    $error("data mismatch: exp: %0x , got: %0x",
                        m_pack.data[WIDTH_S-1:0],
                        s_pack_1.data
                    );

            2'b01: 
                if (s_pack_1.data != m_pack.data[WIDTH_M-1:WIDTH_S])
                    $error("data mismatch: exp: %0x , got: %0x",
                        m_pack.data[WIDTH_M-1:WIDTH_S],
                        s_pack_1.data
                    );
            
            default:
                return s_pack_1;
        endcase

        return null;
    endfunction



    local function void check_double(Packet #(WIDTH_M) m_pack, Packet #(WIDTH_S) s_pack_1);
        
        Packet #(WIDTH_S) s_pack_2 = null;
        logic[WIDTH_M-1:0] merged_data = 0;

        if (s_pack_1 == null)
            return;

        s_pack_2 =  this.slave_queue.pop_front();

        case (m_pack.cfg)
            2'b10:
                merged_data = {s_pack_2.data, s_pack_1.data};

            2'b11: 
                merged_data = {s_pack_1.data, s_pack_2.data};
            
            default:
                return;
        endcase

        if (merged_data != m_pack.data)
            $error("data mismatch: exp: %0x , got: %0x",
             m_pack.data, merged_data);

        if (s_pack_2.last != m_pack.last)
            $error("expected last data; cycle: m_queue_sz: %d, s_queue_sz: %d",
            this.master_queue.size(),
            this.slave_queue.size()
        );

    endfunction


    function void check();
        Packet #(WIDTH_M) m_pack;
        Packet #(WIDTH_S) s_pack_1;

      while (this.master_queue.size() != 0) begin
        m_pack = this.master_queue.pop_front();

        if (this.slave_queue.size() == 0) begin
          $error("Unexpected empty slave queue; m_queue_sz: %d",
           this.master_queue.size());
          break;
        end

        s_pack_1 = this.check_single(m_pack);
        if (s_pack_1 == null)
            continue;

        if (this.slave_queue.size() == 0) begin
            $error("Unexpected empty slave queue; m_queue_sz: %d",
             this.master_queue.size());
            break;
        end

        this.check_double(m_pack, s_pack_1);
        
      end
    endfunction
  endclass
