`include "environment.sv"

//===========================
// Testbench Top
//===========================
module tb;

  spi_if vif();                                 // Virtual interface instance

  top dut (
    vif.clk,
    vif.rst,
    vif.newd,
    vif.din,
    vif.dout,
    vif.done
  );

  // Clock generation
  initial begin
    vif.clk <= 0;
  end

  always #10 vif.clk <= ~vif.clk;

  environment env;

  assign vif.sclk = dut.m1.sclk;

  // Environment setup and execution
  initial begin
    env = new(vif);
    env.gen.count = 4;
    env.run();
  end

  // Dump waveform data
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule
