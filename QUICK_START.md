# Quick Start Guide

## What You Have

This repository contains a complete implementation of the Smart Traffic Light Controller project for ENCS3310.

## Files Overview

```
.
├── traffic_ctrl.v          # Main Verilog FSM implementation
├── traffic_ctrl_tb.v       # Self-checking testbench
├── Makefile                # Build automation
├── README.md               # Complete documentation
├── QUICK_START.md          # This file
└── projectشيرشىؤث.pdf      # Original specification
```

## Get Started in 3 Steps

### Step 1: Install Tools

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install iverilog gtkwave

# macOS
brew install icarus-verilog gtkwave
```

### Step 2: Run Simulation

```bash
make all
```

This will:
- Compile the Verilog files
- Run the testbench
- Display test results
- Generate waveform file

### Step 3: View Waveforms

```bash
make wave
```

This opens GTKWave to visualize the simulation.

## Understanding the Implementation

### FSM States (7 total)

| State | Code | Description | Duration |
|-------|------|-------------|----------|
| M_GREEN | 000 | Main road green | ≥60 cycles |
| M_YELLOW | 001 | Main road yellow | 5 cycles |
| ALL_RED_1 | 010 | Transition to side | 2 cycles |
| S_GREEN | 011 | Side road green | 40 cycles |
| P_WALK | 100 | Pedestrian walk | 40 cycles |
| S_YELLOW | 101 | Side road yellow | 5 cycles |
| ALL_RED_2 | 110 | Transition to main | 2 cycles |

### Key Features Implemented

1. **Default Behavior**: Main road stays green when idle
2. **Vehicle Sensor**: Triggers side road green phase
3. **Pedestrian Button**: Triggers walk signal
4. **Request Latching**: Pedestrian requests queued during side green
5. **Minimum Timing**: Main green enforces 60-cycle minimum
6. **Safety Buffers**: All-red transitions prevent conflicts

### Light Encoding

```verilog
RED    = 3'b100
YELLOW = 3'b010
GREEN  = 3'b001
```

## Test Scenarios Covered

The testbench verifies:
1. Reset and initialization
2. Default state persistence
3. Vehicle sensor triggering
4. Pedestrian button triggering
5. Request queuing mechanism
6. Minimum timing constraints
7. Reset during operation
8. Continuous multi-cycle operation

## Expected Simulation Output

```
========================================
Traffic Light Controller Testbench
========================================

Time=55 | Cycle=5 | State=M_GREEN    | Timer=5 | VS=0 PB=0 | Main=001 Side=100 Walk=0
...

--- Test 0: Reset and Initialization ---
[PASS] After reset: Main should be GREEN, Side RED

--- Test 1: Default State - Main Green Stays ---
[PASS] Main green persists when no requests

...

========================================
Test Summary
========================================
Total Checks: 15
Passed: 15
Failed: 0

*** ALL TESTS PASSED ***
========================================
```

## Viewing Signals in GTKWave

Recommended signals to add to waveform viewer:
1. `clk` - System clock
2. `rst` - Reset signal
3. `VS` - Vehicle sensor
4. `PB` - Pedestrian button
5. `current_state` - FSM state (shows as binary)
6. `timer` - Timing counter
7. `light_main` - Main road light
8. `light_side` - Side road light
9. `walk` - Pedestrian walk signal
10. `pb_request` - Latched pedestrian request

## Troubleshooting

### Tools Not Found
```
iverilog: command not found
```
**Solution**: Install Icarus Verilog (see Step 1 above)

### Permission Denied
```
make: Permission denied
```
**Solution**:
```bash
chmod +x Makefile
```

### Waveform File Not Generated
**Solution**: Ensure simulation completed successfully. Check for errors in output.

## Modifying Timing Parameters

Edit `traffic_ctrl.v` lines 20-24:

```verilog
localparam M_GREEN_MIN = 60;  // Change main green minimum
localparam YELLOW_TIME = 5;   // Change yellow duration
localparam ALL_RED_TIME = 2;  // Change safety buffer
localparam SIDE_TIME = 40;    // Change side green duration
localparam PED_TIME = 40;     // Change pedestrian walk duration
```

After changes:
```bash
make clean
make all
```

## Project Deliverables Checklist

- [x] FSM state diagram (in README.md)
- [x] Verilog implementation (traffic_ctrl.v)
- [x] Testbench (traffic_ctrl_tb.v)
- [x] Simulation logs (run `make all`)
- [x] Waveform (traffic_ctrl.vcd after simulation)
- [ ] Report (≤4 pages) - You need to write this!

## Report Writing Tips

Your report should include:

1. **Introduction** (0.5 page)
   - Problem description
   - System overview

2. **FSM Design** (1 page)
   - State diagram (can use ASCII from README)
   - State encoding choice justification (binary)
   - Transition logic explanation

3. **Implementation** (1 page)
   - Module structure
   - Timer mechanism
   - Pedestrian request latching
   - Reset handling

4. **Verification** (1 page)
   - Test scenarios
   - Simulation results
   - Waveform analysis
   - Pass/fail summary

5. **Conclusion** (0.5 page)
   - What worked well
   - Design decisions
   - Future improvements

## Need Help?

- Check README.md for detailed documentation
- Review projectشيرشىؤث.pdf for original specifications
- Examine comments in traffic_ctrl.v and traffic_ctrl_tb.v
- Run simulation and check console output

## Important Dates

- Deadline: Friday, January 9, 2026 (midnight)
- Late penalty: 10% per day until January 19, 2026

Good luck with your project!
