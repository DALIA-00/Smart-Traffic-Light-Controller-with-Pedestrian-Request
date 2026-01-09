# Smart Traffic Light Controller with Pedestrian Request

## Project Overview
This project implements a Finite State Machine (FSM) based traffic light controller for a main road, side road, and pedestrian crossing. The design is implemented in Verilog and includes a comprehensive self-checking testbench.

## Files Included

1. **traffic_ctrl.v** - Main Verilog implementation of the traffic light controller
2. **traffic_ctrl_tb.v** - Comprehensive self-checking testbench
3. **Makefile** - Build automation for simulation
4. **projectشيرشىؤث.pdf** - Project specification document

## System Specification

### Inputs
- `clk` - System clock
- `rst` - Synchronous reset (active high)
- `VS` - Vehicle Sensor on side road
- `PB` - Pedestrian Button

### Outputs
- `light_main[2:0]` - Main road traffic light {RED, YELLOW, GREEN}
- `light_side[2:0]` - Side road traffic light {RED, YELLOW, GREEN}
- `walk` - Pedestrian walk signal (1=GREEN, 0=RED)

### FSM States

The controller uses 7 states with binary encoding:

1. **M_GREEN** (000) - Main road green (default state)
   - Main: GREEN, Side: RED, Walk: OFF
   - Minimum duration: 60 cycles
   - Stays green while VS=0 and PB=0

2. **M_YELLOW** (001) - Main road yellow transition
   - Main: YELLOW, Side: RED, Walk: OFF
   - Duration: 5 cycles

3. **ALL_RED_1** (010) - Transition safety buffer
   - Main: RED, Side: RED, Walk: OFF
   - Duration: 2 cycles

4. **S_GREEN** (011) - Side road green
   - Main: RED, Side: GREEN, Walk: OFF
   - Duration: 40 cycles exactly

5. **P_WALK** (100) - Pedestrian walk
   - Main: RED, Side: RED, Walk: ON
   - Duration: 40 cycles exactly

6. **S_YELLOW** (101) - Side road yellow transition
   - Main: RED, Side: YELLOW, Walk: OFF
   - Duration: 5 cycles

7. **ALL_RED_2** (110) - Return transition safety buffer
   - Main: RED, Side: RED, Walk: OFF
   - Duration: 2 cycles

### Timing Parameters

- Main green minimum: 60 clock cycles
- Side green: 40 clock cycles (exact)
- Pedestrian walk: 40 clock cycles (exact)
- Yellow lights: 5 clock cycles
- All-red transitions: 2 clock cycles

### Functional Behavior

1. **Default Operation**: Main road stays green indefinitely while no requests are present
2. **Vehicle Detection**: When VS=1 and minimum time elapsed, transition to side green
3. **Pedestrian Request**: When PB=1 and minimum time elapsed, transition to pedestrian walk
4. **Request Queuing**: Pedestrian requests during side green are latched for the next cycle
5. **Priority**: Pedestrian requests have priority over vehicle sensor at transition points

## Design Features

### 1. State Machine Implementation
- Synchronous reset to M_GREEN state
- Binary state encoding for efficiency
- Separate next-state and output logic

### 2. Timer Management
- 7-bit counter (supports up to 127 cycles)
- Automatically resets on state transitions
- Used for enforcing minimum and exact durations

### 3. Pedestrian Request Latching
- PB presses are latched in a register
- Cleared only after pedestrian walk completes
- Enables queuing during side green operation

### 4. Safety Features
- All-red transition states prevent conflicts
- Minimum green times ensure smooth traffic flow
- Exact timing for side road and pedestrian phases

## Testbench Features

The testbench includes comprehensive verification:

1. **Reset and Initialization** - Verifies proper startup
2. **Default State** - Confirms main green persists without requests
3. **Vehicle Sensor** - Tests VS triggering side green
4. **Pedestrian Button** - Tests PB triggering pedestrian walk
5. **Request Queuing** - Verifies pedestrian requests during side green
6. **Minimum Timing** - Ensures main green respects 60-cycle minimum
7. **Reset During Operation** - Tests reset at any state
8. **Continuous Operation** - Multiple complete cycles

### Self-Checking Mechanism
- Automatic pass/fail reporting
- Output verification against expected values
- Timing constraint validation
- Final summary with statistics

## How to Use

### Prerequisites
Install Icarus Verilog and GTKWave:
```bash
# Ubuntu/Debian
sudo apt-get install iverilog gtkwave

# macOS
brew install icarus-verilog gtkwave

# Fedora/RHEL
sudo dnf install iverilog gtkwave
```

### Running Simulation

Using Makefile:
```bash
# Compile and run simulation
make all

# View waveforms
make wave

# Clean generated files
make clean
```

Manual compilation:
```bash
# Compile
iverilog -o traffic_ctrl_sim traffic_ctrl.v traffic_ctrl_tb.v

# Run simulation
vvp traffic_ctrl_sim

# View waveforms
gtkwave traffic_ctrl.vcd
```

### Expected Output

The simulation will display:
- Real-time state transitions
- Timer values
- Input/output signals
- Pass/fail status for each test
- Final summary statistics

Example output:
```
========================================
Traffic Light Controller Testbench
========================================

[PASS] After reset: Main should be GREEN, Side RED
[PASS] Main green persists when no requests
[PASS] Main yellow after VS trigger
...
========================================
Test Summary
========================================
Total Checks: 15
Passed: 15
Failed: 0

*** ALL TESTS PASSED ***
```

## State Transition Diagram

```
         +----------+
    +--->| M_GREEN  |<----+
    |    | Main=G   |     |
    |    | Side=R   |     |
    |    +----------+     |
    |         |           |
    |    VS=1 or PB=1     |
    |    (after 60 cyc)   |
    |         v           |
    |    +----------+     |
    |    |M_YELLOW  |     |
    |    | Main=Y   |     |
    |    | Side=R   |     |
    |    +----------+     |
    |         |           |
    |      5 cycles       |
    |         v           |
    |    +----------+     |
    |    |ALL_RED_1 |     |
    |    | Main=R   |     |
    |    | Side=R   |     |
    |    +----------+     |
    |         |           |
    |    2 cycles         |
    |         v           |
    |    +----------+  +----------+
    |    | S_GREEN  |  | P_WALK   |
    |    | Main=R   |  | Main=R   |
    |    | Side=G   |  | Side=R   |
    |    +----------+  | Walk=ON  |
    |         |        +----------+
    |    40 cycles    40 cycles
    |         |            |
    |         +-----+------+
    |               v
    |          +----------+
    |          |S_YELLOW  |
    |          | Main=R   |
    |          | Side=Y   |
    |          +----------+
    |               |
    |          5 cycles
    |               v
    |          +----------+
    |          |ALL_RED_2 |
    |          | Main=R   |
    |          | Side=R   |
    |          +----------+
    |               |
    |          2 cycles
    +---------------+
```

## Verification Checklist

- [x] FSM state diagram matches specification
- [x] All states properly encoded
- [x] State transitions follow specification
- [x] Timer logic correctly implemented
- [x] Pedestrian request latching works
- [x] Minimum timing constraints enforced
- [x] Output signals correct for each state
- [x] Reset functionality verified
- [x] Self-checking testbench created
- [x] Multiple test scenarios covered

## Project Deliverables

As per course requirements:
1. FSM state diagram - See above ASCII diagram
2. Verilog implementation - traffic_ctrl.v
3. Testbench and simulation logs - traffic_ctrl_tb.v
4. Waveform generation - traffic_ctrl.vcd (generated during simulation)
5. Report - Ready for documentation

## Notes

- Clock period: 10ns (100MHz) in testbench
- All timing values can be adjusted via localparam
- VCD file generated for waveform viewing
- State machine uses Moore-style outputs
- Binary encoding chosen for area efficiency

## Authors

Course: ENCS3310 - Advanced Digital Design
Instructors: Abdellatif Abu-Issa, Ahmad Afaneh, & Elias Khalil
Institution: Birzeit University