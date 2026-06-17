module bit_serial_mac_unsigned #(
    parameter A_WIDTH   = 8,
    parameter W_WIDTH   = 8,
    parameter ACC_WIDTH = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     start,
    input  wire                     in_valid,

    // A is fed bit by bit, LSB first
    input  wire                     a_bit,

    // W is stored / input in parallel
    input  wire [W_WIDTH-1:0]        w,

    // Initial accumulator value
    input  wire [ACC_WIDTH-1:0]      acc_init,

    output reg                      busy,
    output reg                      out_valid,
    output reg  [ACC_WIDTH-1:0]     result
);

    // --------------------------------
    // clog2 function for Verilog
    // --------------------------------
    function integer clog2;
        input integer value;
        integer temp;
        begin
            temp = value - 1;
            clog2 = 0;
            while (temp > 0) begin
                temp = temp >> 1;
                clog2 = clog2 + 1;
            end

            if (clog2 == 0)
                clog2 = 1;
        end
    endfunction

    localparam CNT_WIDTH = clog2(A_WIDTH);

    reg [CNT_WIDTH-1:0] bit_idx;
    reg [ACC_WIDTH-1:0] acc;

    wire [ACC_WIDTH-1:0] w_ext;
    wire [ACC_WIDTH-1:0] shifted_w;
    wire [ACC_WIDTH-1:0] addend;
    wire [ACC_WIDTH-1:0] acc_next;

    assign w_ext     = {{(ACC_WIDTH-W_WIDTH){1'b0}}, w};
    assign shifted_w = w_ext << bit_idx;
    assign addend    = a_bit ? shifted_w : {ACC_WIDTH{1'b0}};
    assign acc_next  = acc + addend;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy      <= 1'b0;
            out_valid <= 1'b0;
            result    <= {ACC_WIDTH{1'b0}};
            acc       <= {ACC_WIDTH{1'b0}};
            bit_idx   <= {CNT_WIDTH{1'b0}};
        end
        else begin
            out_valid <= 1'b0;

            if (start && !busy) begin
                busy    <= 1'b1;
                acc     <= acc_init;
                bit_idx <= {CNT_WIDTH{1'b0}};
            end
            else if (busy && in_valid) begin
                acc <= acc_next;

                if (bit_idx == A_WIDTH - 1) begin
                    busy      <= 1'b0;
                    out_valid <= 1'b1;
                    result    <= acc_next;
                end
                else begin
                    bit_idx <= bit_idx + 1'b1;
                end
            end
        end
    end

endmodule