# Simulation Results Analysis - User's Code

## Summary

Your testbench ran successfully! Here's what the simulation revealed:

## Key Observations

### ✅ What Works:

1. **Reset works correctly** - System starts in Main GREEN state (State=0011000)
2. **Timer counting** - Timer increments properly each clock cycle
3. **State transitions occur** - FSM transitions through states
4. **Pedestrian request latching** - PB pressed at 52ns was latched and served later

### ❌ Critical Issues Found:

1. **Main Green ALWAYS exits after 61 cycles**
   - Spec says: "may stay green as long as VS=0 and PB=0"
   - Your code: Always transitions to yellow after timer reaches 60
   - **Time 61.5µs**: Transitions from GREEN→YELLOW even though VS=0, PB=0

2. **All-Red (RRR) lasts 41 cycles instead of 2**
   - Spec requires: 2 cycles
   - Your code: 41 cycles (Time 68.5µs to 109.5µs)
   - This is a 20× timing error!

3. **Pedestrian Walk lasts only 6 cycles instead of 40**
   - Spec requires: 40 cycles
   - Your code: 6 cycles (Time 109.5µs to 115.5µs)
   - This is an 8× timing error!

4. **No Side Green observed**
   - The system went: Main GREEN → Main YELLOW → ALL_RED → Pedestrian WALK
   - Never reached Side GREEN state (RGR = 1000010)

## Timeline Analysis

```
Time Range      | State    | Duration | Expected | Status
----------------|----------|----------|----------|--------
0 - 61.5µs      | M_GREEN  | 61 cyc   | 60+ cyc  | ❌ Off by 1
61.5 - 68.5µs   | M_YELLOW | 6 cyc    | 5 cyc    | ❌ Off by 1
68.5 - 109.5µs  | ALL_RED  | 41 cyc   | 2 cyc    | ❌ 20× too long!
109.5 - 115.5µs | PED_WALK | 6 cyc    | 40 cyc   | ❌ 8× too short!
115.5 - 156.5µs | ALL_RED  | 41 cyc   | 2 cyc    | ❌ 20× too long!
156.5+ µs       | M_GREEN  | -        | -        | ✅ Returns to green
```

## Root Causes

### 1. Timer Off-by-One Error
```verilog
if (timer >= timer_limit) timer <= 0;  // BAD
```
This causes states to last `timer_limit + 1` cycles because timer goes 0→1→...→timer_limit (that's timer_limit+1 values).

**Fix:**
```verilog
if (timer >= timer_limit - 1) timer <= 0;  // GOOD
```

### 2. Wrong Timer Limits
```verilog
case (state)
    GRR: timer_limit = 60;   // ✓ OK
    RGR: timer_limit = 40;   // ✓ OK (but never reached!)
    RRR: timer_limit = 40;   // ❌ Should be 2
    default: timer_limit = 5; // RRG gets this → ❌ Should be 40
endcase
```

### 3. Main Green Always Transitions
```verilog
GRR: state <= YRR;  // BAD - always transitions
```

**Fix:**
```verilog
GRR: begin
    if (VS || PB || PB_queued)
        state <= YRR;
    else
        state <= GRR;  // Stay green!
end
```

## Detailed State Observations

### State Encoding (from simulation):
- `0011000` = Main GREEN, Side RED, Walk OFF
- `0101000` = Main YELLOW, Side RED, Walk OFF
- `1001000` = All RED (RRR)
- `1001001` = All RED with Walk ON (RRG = Pedestrian)
- `1000010` = Side GREEN (never reached)

### Why No Side Green?

When PB was pressed at 52ns, the system:
1. Waited until timer=60 in Main GREEN
2. Went to Main YELLOW (6 cycles)
3. Went to ALL_RED (41 cycles)
4. Checked: `if (PB_queued || PB) state <= RRG;` ✓ TRUE
5. Went to PEDESTRIAN WALK (6 cycles)
6. Back to ALL_RED, then Main GREEN

The pedestrian request had priority, so Side GREEN was skipped!

## Comparison with Spec

| Requirement | Spec | Your Code | Result |
|-------------|------|-----------|--------|
| Module name | `traffic_ctrl` | `SmartTrafficLight` | ❌ |
| Reset type | Sync active-high | Async active-low | ❌ |
| Main green min | 60 cycles | 61 cycles | ❌ |
| Main stays green | Indefinitely if no requests | Always 61 cycles | ❌ |
| Yellow duration | 5 cycles | 6 cycles | ❌ |
| All-red duration | 2 cycles | 41 cycles | ❌ |
| Side green | 40 cycles | Not reached | ❌ |
| Ped walk | 40 cycles | 6 cycles | ❌ |
| PB latching | Yes | ✅ Works | ✅ |
| State encoding | Any valid | Direct output | ✅ Clever! |

## Recommendations

1. **Use the fixed version** (`SmartTrafficLight_fixed.v`) which corrects all these issues
2. **Or manually fix** the 7 issues listed in COMPARISON.md
3. **Test thoroughly** - your testbench is too short, extend it to test:
   - Side green with vehicle sensor
   - Multiple complete cycles
   - Timing verification

## Waveform Available

A VCD file was generated: `testTrafficSystem.vcd`

To view it:
```bash
gtkwave testTrafficSystem.vcd
```

## Next Steps

Would you like me to:
1. Run the fixed version for comparison?
2. Create a more comprehensive testbench?
3. Show side-by-side timing comparison?
