# Makefile for Traffic Light Controller Simulation

# Compiler and simulator
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Source files
SRC = traffic_ctrl.v
TB = traffic_ctrl_tb.v
OUT = traffic_ctrl_sim
VCD = traffic_ctrl.vcd

# Default target
all: compile run

# Compile Verilog files
compile:
	@echo "Compiling Verilog files..."
	$(IVERILOG) -o $(OUT) $(SRC) $(TB)
	@echo "Compilation complete!"

# Run simulation
run:
	@echo "Running simulation..."
	$(VVP) $(OUT)
	@echo "Simulation complete!"

# View waveform
wave:
	@echo "Opening waveform viewer..."
	$(GTKWAVE) $(VCD) &

# Clean generated files
clean:
	@echo "Cleaning up..."
	rm -f $(OUT) $(VCD)
	@echo "Clean complete!"

# Help
help:
	@echo "Available targets:"
	@echo "  make all     - Compile and run simulation"
	@echo "  make compile - Compile Verilog files only"
	@echo "  make run     - Run simulation only"
	@echo "  make wave    - Open GTKWave to view waveforms"
	@echo "  make clean   - Remove generated files"
	@echo "  make help    - Show this help message"

.PHONY: all compile run wave clean help
