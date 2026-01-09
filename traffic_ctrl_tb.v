// Testbench for Smart Traffic Light Controller
// Self-checking testbench with comprehensive test scenarios

`timescale 1ns/1ps

module traffic_ctrl_tb;

    // Testbench signals
    reg clk;
    reg rst;
    reg VS;
    reg PB;
    wire [2:0] light_main;
    wire [2:0] light_side;
    wire walk;

    // Test control variables
    integer test_num;
    integer pass_count;
    integer fail_count;
    integer cycle_count;

    // Light encoding for checking
    localparam RED    = 3'b100;
    localparam YELLOW = 3'b010;
    localparam GREEN  = 3'b001;

    // State names for display
    reg [127:0] state_name;

    // Instantiate DUT (Device Under Test)
    traffic_ctrl DUT (
        .clk(clk),
        .rst(rst),
        .VS(VS),
        .PB(PB),
        .light_main(light_main),
        .light_side(light_side),
        .walk(walk)
    );

    // Clock generation (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Cycle counter
    always @(posedge clk) begin
        if (rst)
            cycle_count = 0;
        else
            cycle_count = cycle_count + 1;
    end

    // State decoder for display
    always @(*) begin
        case (DUT.current_state)
            3'b000: state_name = "M_GREEN";
            3'b001: state_name = "M_YELLOW";
            3'b010: state_name = "ALL_RED_1";
            3'b011: state_name = "S_GREEN";
            3'b100: state_name = "P_WALK";
            3'b101: state_name = "S_YELLOW";
            3'b110: state_name = "ALL_RED_2";
            default: state_name = "UNKNOWN";
        endcase
    end

    // Display monitor
    initial begin
        $display("\n========================================");
        $display("Traffic Light Controller Testbench");
        $display("========================================\n");
        $monitor("Time=%0t | Cycle=%0d | State=%-10s | Timer=%0d | VS=%b PB=%b | Main=%b Side=%b Walk=%b",
                 $time, cycle_count, state_name, DUT.timer, VS, PB, light_main, light_side, walk);
    end

    // Helper task to check expected outputs
    task check_outputs;
        input [2:0] exp_main;
        input [2:0] exp_side;
        input exp_walk;
        input [200:0] test_desc;
        begin
            if (light_main === exp_main && light_side === exp_side && walk === exp_walk) begin
                $display("[PASS] %s", test_desc);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %s", test_desc);
                $display("       Expected: Main=%b Side=%b Walk=%b", exp_main, exp_side, exp_walk);
                $display("       Got:      Main=%b Side=%b Walk=%b", light_main, light_side, walk);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Helper task to wait for a specific state
    task wait_for_state;
        input [2:0] target_state;
        input integer timeout_cycles;
        integer wait_count;
        begin
            wait_count = 0;
            while (DUT.current_state !== target_state && wait_count < timeout_cycles) begin
                @(posedge clk);
                wait_count = wait_count + 1;
            end
            if (wait_count >= timeout_cycles) begin
                $display("[WARNING] Timeout waiting for state %b", target_state);
            end
        end
    endtask

    // Main test sequence
    initial begin
        // Initialize
        test_num = 0;
        pass_count = 0;
        fail_count = 0;
        rst = 1;
        VS = 0;
        PB = 0;
        cycle_count = 0;

        // Reset sequence
        $display("\n--- Test %0d: Reset and Initialization ---", test_num);
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);
        check_outputs(GREEN, RED, 0, "After reset: Main should be GREEN, Side RED");

        // Test 1: Default state (Main stays green)
        test_num = test_num + 1;
        $display("\n--- Test %0d: Default State - Main Green Stays ---", test_num);
        repeat(70) @(posedge clk);
        check_outputs(GREEN, RED, 0, "Main green persists when no requests");

        // Test 2: Vehicle sensor triggers transition
        test_num = test_num + 1;
        $display("\n--- Test %0d: Vehicle Sensor Triggers Side Green ---", test_num);
        VS = 1;
        @(posedge clk);
        VS = 0;

        // Wait for M_YELLOW state
        wait_for_state(3'b001, 100);
        check_outputs(YELLOW, RED, 0, "Main yellow after VS trigger");

        // Wait through transitions to S_GREEN
        wait_for_state(3'b011, 100);
        check_outputs(RED, GREEN, 0, "Side green after transitions");

        // Verify side green duration
        repeat(40) @(posedge clk);
        wait_for_state(3'b101, 10);
        check_outputs(RED, YELLOW, 0, "Side yellow after 40 cycles");

        // Return to main green
        wait_for_state(3'b000, 100);
        check_outputs(GREEN, RED, 0, "Back to main green");

        // Test 3: Pedestrian button triggers walk signal
        test_num = test_num + 1;
        $display("\n--- Test %0d: Pedestrian Button Triggers Walk ---", test_num);

        // Wait for main green minimum time
        repeat(60) @(posedge clk);

        PB = 1;
        @(posedge clk);
        PB = 0;

        // Should go through M_YELLOW -> ALL_RED_1 -> P_WALK
        wait_for_state(3'b001, 100);
        check_outputs(YELLOW, RED, 0, "Main yellow after PB trigger");

        wait_for_state(3'b100, 100);
        check_outputs(RED, RED, 1, "Pedestrian walk active");

        // Verify pedestrian walk duration
        repeat(40) @(posedge clk);
        wait_for_state(3'b101, 10);
        check_outputs(RED, YELLOW, 0, "Side yellow after pedestrian walk");

        wait_for_state(3'b000, 100);
        check_outputs(GREEN, RED, 0, "Back to main green after pedestrian");

        // Test 4: Pedestrian request during side green (queuing)
        test_num = test_num + 1;
        $display("\n--- Test %0d: Pedestrian Request Queuing ---", test_num);

        repeat(60) @(posedge clk);

        // Trigger vehicle sensor to get to side green
        VS = 1;
        @(posedge clk);
        VS = 0;

        wait_for_state(3'b011, 100);
        $display("[INFO] Reached side green state");

        // Press pedestrian button during side green
        repeat(10) @(posedge clk);
        PB = 1;
        @(posedge clk);
        PB = 0;
        $display("[INFO] Pedestrian button pressed during side green");

        // Should complete side green cycle first
        wait_for_state(3'b101, 50);
        check_outputs(RED, YELLOW, 0, "Side yellow completes normally");

        // Return to main green (pedestrian queued for next cycle)
        wait_for_state(3'b000, 100);
        check_outputs(GREEN, RED, 0, "Returned to main green");

        // Verify pedestrian request is latched
        repeat(60) @(posedge clk);
        wait_for_state(3'b100, 100);
        check_outputs(RED, RED, 1, "Queued pedestrian request served");

        // Test 5: Minimum timing verification
        test_num = test_num + 1;
        $display("\n--- Test %0d: Minimum Timing Verification ---", test_num);

        wait_for_state(3'b000, 100);

        // Try to trigger transition before minimum time
        repeat(30) @(posedge clk);
        VS = 1;
        repeat(10) @(posedge clk);
        VS = 0;

        // Should still be in main green (hasn't reached 60 cycles)
        if (DUT.current_state == 3'b000) begin
            $display("[PASS] Main green respects minimum time");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Main green transitioned too early");
            fail_count = fail_count + 1;
        end

        // Wait for minimum and trigger again
        repeat(30) @(posedge clk);
        VS = 1;
        @(posedge clk);
        VS = 0;

        wait_for_state(3'b001, 10);
        if (DUT.current_state == 3'b001) begin
            $display("[PASS] Transition occurs after minimum time");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Failed to transition after minimum time");
            fail_count = fail_count + 1;
        end

        // Test 6: Reset during operation
        test_num = test_num + 1;
        $display("\n--- Test %0d: Reset During Operation ---", test_num);

        wait_for_state(3'b011, 100);  // Get to side green

        // Apply reset
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        check_outputs(GREEN, RED, 0, "Reset returns to main green immediately");

        // Test 7: Continuous operation test
        test_num = test_num + 1;
        $display("\n--- Test %0d: Continuous Operation Test ---", test_num);

        repeat(3) begin
            repeat(60) @(posedge clk);
            VS = 1;
            @(posedge clk);
            VS = 0;
            wait_for_state(3'b011, 100);
            wait_for_state(3'b000, 200);
        end
        $display("[INFO] Completed 3 full cycles successfully");

        // Final results
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total Checks: %0d", pass_count + fail_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);

        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED ***\n");
        end

        $display("========================================\n");

        $finish;
    end

    // Waveform dump for viewing in simulator
    initial begin
        $dumpfile("traffic_ctrl.vcd");
        $dumpvars(0, traffic_ctrl_tb);
    end

    // Timeout watchdog
    initial begin
        #1000000;  // 1ms timeout
        $display("\n[ERROR] Simulation timeout!");
        $finish;
    end

endmodule
