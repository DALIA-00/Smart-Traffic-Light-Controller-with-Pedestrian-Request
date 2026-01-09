module testTrafficSystem;
    reg clk, rst, VS, PB;
    wire [2:0] light_main;
    wire [2:0] light_side;
    wire walk;

    SmartTrafficLight DUT(
        .clk(clk),
        .rst(rst),
        .VS(VS),
        .PB(PB),
        .light_main(light_main),
        .light_side(light_side),
        .walk(walk)
    );

    // Clock generation - 1 second cycle (500ns half period)
    always #500 clk = ~clk;

    // Decode lights for display
    reg [10*8:1] main_light_str;
    reg [10*8:1] side_light_str;

    always @(*) begin
        case (light_main)
            3'b100: main_light_str = "RED   ";
            3'b010: main_light_str = "YELLOW";
            3'b001: main_light_str = "GREEN ";
            default: main_light_str = "ERROR ";
        endcase

        case (light_side)
            3'b100: side_light_str = "RED   ";
            3'b010: side_light_str = "YELLOW";
            3'b001: side_light_str = "GREEN ";
            default: side_light_str = "ERROR ";
        endcase
    end

    // Monitor with decoded outputs
    initial begin
        $display("\n========================================");
        $display("Traffic System Testbench (User's Code)");
        $display("========================================\n");
        $monitor("Time=%0t ns | VS=%b PB=%b | Main=%-6s Side=%-6s Walk=%b | State=%b Timer=%0d",
                 $time, VS, PB, main_light_str, side_light_str, walk,
                 DUT.state, DUT.timer);
    end

    initial begin
        // Initialize
        rst = 0;  // Active-low reset asserted
        clk = 0;
        VS = 0;
        PB = 0;

        #2000 rst = 1;  // Release reset after 2 clock cycles

        $display("\n--- Phase 1: No requests (VS=0, PB=0) ---");
        #10000 VS = 0; PB = 0;  // 10 cycles

        $display("\n--- Phase 2: Vehicle sensor active (VS=1, PB=0) ---");
        #20000 VS = 1; PB = 0;  // 20 cycles

        $display("\n--- Phase 3: Pedestrian button active (VS=0, PB=1) ---");
        #20000 VS = 0; PB = 1;  // 20 cycles

        $display("\n--- Phase 4: Both active (VS=1, PB=1) ---");
        #20000 VS = 1; PB = 1;  // 20 cycles

        $display("\n--- Phase 5: No requests again (VS=0, PB=0) ---");
        #20000 VS = 0; PB = 0;  // 20 cycles

        // Let it run for much longer to see complete cycles
        $display("\n--- Phase 6: Extended observation (300 cycles) ---");
        #300000;

        $display("\n========================================");
        $display("Simulation Finished");
        $display("========================================\n");
        $finish;
    end

    // Generate VCD for waveform viewing
    initial begin
        $dumpfile("testTrafficSystem.vcd");
        $dumpvars(0, testTrafficSystem);
    end
endmodule
