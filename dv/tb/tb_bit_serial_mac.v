`timescale 1ns/1ps

module tb_bit_serial_mac;

    reg clk;
    reg rst_n;
    reg start;
    reg in_valid;
    reg a_bit;

    reg  [7:0]  w;
    reg  [31:0] acc_init;

    wire busy;
    wire out_valid;
    wire [31:0] result;

    // 全局错误计数器
    integer fail_cnt;

`ifndef GATE_SIM
    bit_serial_mac_unsigned #(
        .A_WIDTH(8),
        .W_WIDTH(8),
        .ACC_WIDTH(32)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .in_valid(in_valid),
        .a_bit(a_bit),
        .w(w),
        .acc_init(acc_init),
        .busy(busy),
        .out_valid(out_valid),
        .result(result)
    );
`else
    bit_serial_mac_unsigned dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .in_valid(in_valid),
        .a_bit(a_bit),
        .w(w),
        .acc_init(acc_init),
        .busy(busy),
        .out_valid(out_valid),
        .result(result)
    );
`endif

    // 时钟生成
    always #5 clk = ~clk;

    // 波形转储（可选）
    `ifdef DUMP_VCD
    string dumpfile;
    initial begin
        if (!$value$plusargs("DUMPFILE=%s", dumpfile)) begin
            dumpfile = "wave.vcd";
        end
        $dumpfile(dumpfile);
        $dumpvars(0, tb_bit_serial_mac);
    end
    `endif

    integer seed;
    reg [1023:0] test_name;

    // 顶层 initial 块
    initial begin
        // 初始化信号
        clk      = 0;
        rst_n    = 0;
        start    = 0;
        in_valid = 0;
        a_bit    = 0;
        w        = 8'd0;
        acc_init = 32'd0;
        fail_cnt = 0;

        // 复位释放
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        // 获取测试名与随机种子
        if (!$value$plusargs("TEST_NAME=%s", test_name)) begin
            test_name = "basic";
        end
        if (!$value$plusargs("SEED=%d", seed)) begin
            seed = 1;
        end

        $display("TEST_NAME = %0s", test_name);
        $display("SEED      = %0d", seed);

        // 根据 TEST_NAME 调用对应的测试
        if (test_name == "basic") begin
            run_basic_test();
        end
        else if (test_name == "corner") begin
            run_corner_test();
        end
        else if (test_name == "random") begin
            run_random_test(seed);
        end
        else begin
            $display("FAIL: unknown TEST_NAME = %0s", test_name);
            $finish;
        end

        // 汇总结果
        if (fail_cnt == 0) begin
            $display("PASS");
        end
        else begin
            $display("FAIL");
        end
        $finish;
    end

    // --------------------------------------------------------
    // 通用任务：发送一次完整的位串行计算并检查结果
    // --------------------------------------------------------
task send_and_check;
    input [7:0]  A;
    input [7:0]  W;
    input [31:0] acc_init_val;
    input [31:0] expected;
    integer i;
begin
    // 等待 DUT 空闲
    wait (busy == 1'b0);

    // 在 negedge 改输入，保证 posedge 前信号稳定
    @(negedge clk);
    w        = W;
    acc_init = acc_init_val;
    a_bit    = 1'b0;
    in_valid = 1'b0;
    start    = 1'b0;

    // 产生 start 脉冲，一个完整时钟周期
    @(negedge clk);
    start = 1'b1;

    @(negedge clk);
    start = 1'b0;

    // LSB first 逐位送入 A
    for (i = 0; i < 8; i = i + 1) begin
        a_bit    = A[i];
        in_valid = 1'b1;
        @(negedge clk);
    end

    // 最后一位已经在上一个 posedge 被 DUT 采样
    in_valid = 1'b0;
    a_bit    = 1'b0;

    // 此时 out_valid/result 应该已经由最后一个 posedge 更新完成
    if (out_valid !== 1'b1) begin
        $display("FAIL: out_valid not high after sending all bits. A=%0d, W=%0d, acc_init=%0d",
                 A, W, acc_init_val);
        fail_cnt = fail_cnt + 1;
    end
    else if (result !== expected) begin
        $display("FAIL: result mismatch. A=%0d, W=%0d, acc_init=%0d, Expected=%0d, Got=%0d",
                 A, W, acc_init_val, expected, result);
        fail_cnt = fail_cnt + 1;
    end
    else begin
        $display("OK: A=%0d, W=%0d, acc_init=%0d -> result=%0d",
                 A, W, acc_init_val, result);
    end

    // 等待 out_valid 自动清零
    @(negedge clk);
end
endtask

    // --------------------------------------------------------
    // 基本测试
    // --------------------------------------------------------
    task run_basic_test;
    begin
        // A=11, W=6, acc_init=0 → 期望 66
        send_and_check(8'd11, 8'd6, 32'd0, 32'd66);
        // 附加：带非零初始累加值的测试
        send_and_check(8'd11, 8'd6, 32'd5, 32'd71);
    end
    endtask

    // --------------------------------------------------------
    // 边界与角落测试
    // --------------------------------------------------------
    task run_corner_test;
    begin
        // 零值
        send_and_check(8'd0, 8'd0, 32'd0, 32'd0);
        // 最大值乘积
        send_and_check(8'd255, 8'd255, 32'd0, 32'd65025);
        // A=0，仅依赖 acc_init
        send_and_check(8'd0, 8'd255, 32'd123, 32'd123);
        // W=0
        send_and_check(8'd255, 8'd0, 32'd0, 32'd0);
        // 小值 + 非零 acc_init
        send_and_check(8'd1, 8'd1, 32'd123456, 32'd123457);
        // 累加器接近最大值，测试无溢出环绕
        send_and_check(8'd255, 8'd255, (32'hFFFF_FFFF - 32'd65025), 32'hFFFF_FFFF);
        // 溢出测试：最大值 + 1 → 环绕到 0
        send_and_check(8'd1, 8'd1, 32'hFFFF_FFFF, 32'd0);
    end
    endtask

    // --------------------------------------------------------
    // 随机测试（100 次）
    // --------------------------------------------------------
    task run_random_test;
        input integer seed;
        integer i;
        integer seed_var;
        reg [7:0]  A;
        reg [7:0]  W;
        reg [31:0] acc_init_val;
        reg [31:0] expected;
    begin
        seed_var = seed;
        for (i = 0; i < 100; i = i + 1) begin
            A             = $random(seed_var) & 8'hFF;
            W             = $random(seed_var) & 8'hFF;
            acc_init_val  = $random(seed_var);      // 32 位
            expected      = acc_init_val + A * W;   // 32 位自动环绕
            send_and_check(A, W, acc_init_val, expected);
        end
    end
    endtask

endmodule