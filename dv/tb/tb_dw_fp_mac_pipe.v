`timescale 1ns/1ps

module tb_dw_fp_mac_pipe;

    localparam SIG_WIDTH       = 23;
    localparam EXP_WIDTH       = 8;
    localparam IEEE_COMPLIANCE = 0;
    localparam FP_WIDTH        = SIG_WIDTH + EXP_WIDTH + 1;

    reg clk;
    reg rst_n;

    reg                  in_valid;
    reg [FP_WIDTH-1:0]   a;
    reg [FP_WIDTH-1:0]   b;
    reg [FP_WIDTH-1:0]   c;
    reg [2:0]            rnd;

    wire                 out_valid;
    wire [FP_WIDTH-1:0]  z;
    wire [7:0]           status;

    integer error_count;

    // Instance name must remain "dut" because SDF GLS uses:
    // SCOPE = tb_dw_fp_mac_pipe.dut
    dw_fp_mac_pipe #(
        SIG_WIDTH,
        EXP_WIDTH,
        IEEE_COMPLIANCE
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_valid  (in_valid),
        .a         (a),
        .b         (b),
        .c         (c),
        .rnd       (rnd),
        .out_valid (out_valid),
        .z         (z),
        .status    (status)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

`ifdef DUMP_VCD
    reg [1023:0] dumpfile;

    initial begin
        if (!$value$plusargs("DUMPFILE=%s", dumpfile))
            dumpfile = "wave.vcd";

        $dumpfile(dumpfile);
        $dumpvars(0, tb_dw_fp_mac_pipe);
    end
`endif

    task send_and_check;
        input [31:0] test_a;
        input [31:0] test_b;
        input [31:0] test_c;
        input [31:0] expected_z;
        begin
            // Avoid testbench/DUT race by driving at negedge.
            @(negedge clk);
            a        = test_a;
            b        = test_b;
            c        = test_c;
            rnd      = 3'b000;
            in_valid = 1'b1;

            @(negedge clk);
            in_valid = 1'b0;

            wait (out_valid === 1'b1);
            #1;

            if (z !== expected_z) begin
                $display(
                    "FAIL: a=%h b=%h c=%h expected=%h got=%h status=%h",
                    test_a, test_b, test_c, expected_z, z, status
                );
                error_count = error_count + 1;
            end
            else begin
                $display(
                    "OK: a=%h b=%h c=%h -> z=%h status=%h",
                    test_a, test_b, test_c, z, status
                );
            end
        end
    endtask

    initial begin
        error_count = 0;

        rst_n    = 1'b0;
        in_valid = 1'b0;
        a        = 32'b0;
        b        = 32'b0;
        c        = 32'b0;
        rnd      = 3'b000;

        repeat (4) @(negedge clk);
        rst_n = 1'b1;

        // 1.0 * 2.0 + 0.5 = 2.5
        send_and_check(
            32'h3f800000,
            32'h40000000,
            32'h3f000000,
            32'h40200000
        );

        // 2.0 * 3.0 + 1.0 = 7.0
        send_and_check(
            32'h40000000,
            32'h40400000,
            32'h3f800000,
            32'h40e00000
        );

        // -1.0 * 2.0 + 0.5 = -1.5
        send_and_check(
            32'hbf800000,
            32'h40000000,
            32'h3f000000,
            32'hbfc00000
        );

        // 0.0 * 100.0 + 1.0 = 1.0
        send_and_check(
            32'h00000000,
            32'h42c80000,
            32'h3f800000,
            32'h3f800000
        );

        if (error_count == 0) begin
            $display("PASS");
        end
        else begin
            $display("FAIL");
        end

        $finish;
    end

endmodule