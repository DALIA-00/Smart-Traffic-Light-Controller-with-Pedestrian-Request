// Simple Timer Test
module timer_test;
    reg clk, rst;
    wire [6:0] timer;

    // Simplified timer logic to test
    reg [6:0] timer_reg;
    assign timer = timer_reg;

    always @(posedge clk) begin
        if (rst)
            timer_reg <= 0;
        else
            timer_reg <= timer_reg + 1;
    end

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Test
    initial begin
        $display("Timer Test");
        $monitor("Time=%0t | rst=%b | timer=%0d", $time, rst, timer);

        // Assert reset
        rst = 1;
        #20;

        // Release reset
        rst = 0;
        #200;

        if (timer > 15) begin
            $display("\n[PASS] Timer is counting correctly! Timer=%0d", timer);
        end else begin
            $display("\n[FAIL] Timer stuck at %0d", timer);
        end

        $finish;
    end
endmodule
