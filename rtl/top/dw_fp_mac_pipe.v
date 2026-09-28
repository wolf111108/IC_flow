`timescale 1ns/1ps

module dw_fp_mult_pipe #(
    parameter SIG_WIDTH       = 23,
    parameter EXP_WIDTH       = 8,
    parameter IEEE_COMPLIANCE = 0
) (
    input  wire                         clk,
    input  wire                         rst_n,

    input  wire                         in_valid,
    input  wire [SIG_WIDTH+EXP_WIDTH:0] a,
    input  wire [SIG_WIDTH+EXP_WIDTH:0] b,
    input  wire [2:0]                   rnd,

    output reg                          out_valid,
    output reg  [SIG_WIDTH+EXP_WIDTH:0] z,
    output reg  [7:0]                   status
);

    localparam FP_WIDTH = SIG_WIDTH + EXP_WIDTH + 1;

    reg [FP_WIDTH-1:0] a_reg;
    reg [FP_WIDTH-1:0] b_reg;
    reg [2:0]          rnd_reg;
    reg                valid_reg;

    wire [FP_WIDTH-1:0] dw_z;
    wire [7:0]          dw_status;

    // --------------------------------------------------------
    // DesignWare floating-point multiplier
    //
    // z = a * b
    // --------------------------------------------------------

    DW_fp_mult #(
        SIG_WIDTH,
        EXP_WIDTH,
        IEEE_COMPLIANCE
    ) u_dw_fp_mult (
        .a      (a_reg),
        .b      (b_reg),
        .rnd    (rnd_reg),
        .z      (dw_z),
        .status (dw_status)
    );

    // --------------------------------------------------------
    // Input and output registers
    //
    // Input sampled at cycle N.
    // Result becomes valid at cycle N+1.
    // --------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg     <= {FP_WIDTH{1'b0}};
            b_reg     <= {FP_WIDTH{1'b0}};
            rnd_reg   <= 3'b000;
            valid_reg <= 1'b0;

            z         <= {FP_WIDTH{1'b0}};
            status    <= 8'b0;
            out_valid <= 1'b0;
        end
        else begin
            a_reg     <= a;
            b_reg     <= b;
            rnd_reg   <= rnd;
            valid_reg <= in_valid;

            z         <= dw_z;
            status    <= dw_status;
            out_valid <= valid_reg;
        end
    end

endmodule