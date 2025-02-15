

module axi_cdc #(
    parameter WIDTH_P = 64,
    WIDTH_S = 32
) (
    input wire clk_p,
    input wire clk_s,

    input wire rst_p,
    input wire rst_s,

    input wire [1:0] cfg,

    input  wire [WIDTH_P-1:0] p_axis_data,
    input  wire               p_axis_valid,
    input  wire               p_axis_last,
    output wire               p_axis_ready,


    output wire [WIDTH_S-1:0] s_axis_data,
    output wire               s_axis_valid,
    output wire               s_axis_last,
    input  wire               s_axis_ready

);


  logic w_full;
  logic r_empty;

  logic [WIDTH_S:0] r_data;

  logic [WIDTH_S:0] w_data;
  logic push;

  fifo_async #(
      .WIDTH(WIDTH_S + 1),
      .DEPTH(8)
  ) fifo (
      .w_clk (clk_p),
      .w_rst (rst_p),
      .w_data(w_data),
      .push  (push),
      .w_full(w_full),

      .r_clk  (clk_s),
      .r_rst  (rst_s),
      .r_data (r_data),
      .pop    (s_axis_ready),
      .r_empty(r_empty)
  );


  assign s_axis_data  = r_data[WIDTH_S-1 : 0];
  assign s_axis_last  = r_data[WIDTH_S];
  assign s_axis_valid = ~r_empty;


  enum logic [2:0] {
    IDLE = 3'b100,
    LSB = 3'b000,
    MSB = 3'b001,
    LITTLE_ENDIAN = 3'b010,
    BIG_ENDIAN = 3'b011
  }
      state, new_state;


  always_ff @(posedge clk_p)
    if (!rst_p) state <= IDLE;
    else state <= new_state;


  assign p_axis_ready = !w_full && (state == IDLE || state == MSB || state == LSB);

  assign handshake = p_axis_ready && p_axis_valid;


  reg [WIDTH_P-1:0] w_data_buf;
  reg               w_axis_last_buf;

  always_ff @(posedge clk_p or negedge rst_p) begin
    if (!rst_p) begin
      w_data_buf <= 0;
      w_axis_last_buf <= 0;
    end else begin
      if (handshake) begin
        {w_axis_last_buf, w_data_buf} <= {p_axis_last, p_axis_data};
      end
    end
  end


  always_comb begin
    new_state = state;

    case (state)
      IDLE: begin
        if (handshake) begin
          case (cfg)
            2'b00: new_state = LSB;
            2'b01: new_state = MSB;
            2'b10: new_state = LITTLE_ENDIAN;
            2'b11: new_state = BIG_ENDIAN;
          endcase
        end
      end

      LSB, MSB: begin
        if (handshake)
          case (cfg)
            2'b00: new_state = LSB;
            2'b01: new_state = MSB;
            2'b10: new_state = LITTLE_ENDIAN;
            2'b11: new_state = BIG_ENDIAN;
          endcase
        else if (w_full) new_state = state;
        else new_state = IDLE;
      end

      LITTLE_ENDIAN: begin
        new_state = MSB;
      end
      BIG_ENDIAN: begin
        new_state = LSB;
      end
      
      default:begin end
    endcase
  end


  assign push = (state != IDLE);

  always_comb begin

      if (state == LSB) begin
        w_data = {w_axis_last_buf, w_data_buf[WIDTH_S-1 : 0]};
       
      end
      else if (state == MSB) begin
        w_data = {w_axis_last_buf, w_data_buf[WIDTH_P-1 : WIDTH_S]};
        
      end

      else if (state == LITTLE_ENDIAN) begin
        w_data = {1'b0, w_data_buf[WIDTH_S-1 : 0]};
        
      end

      else begin
        w_data = {1'b0, w_data_buf[WIDTH_P-1 : WIDTH_S]};
       
      end


  end



endmodule
