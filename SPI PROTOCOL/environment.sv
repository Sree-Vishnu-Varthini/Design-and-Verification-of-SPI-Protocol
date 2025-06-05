`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "interface.sv"

//===========================
// Environment Class
//===========================
class environment;

  generator  gen;                    // Generator object
  driver     drv;                    // Driver object
  monitor    mon;                    // Monitor object
  scoreboard sco;                    // Scoreboard object

  event nextgd;                      // Event for generator to driver communication
  event nextgs;                      // Event for generator to scoreboard communication

  mailbox #(transaction)  mbxgd;     // Mailbox for generator to driver communication
  mailbox #(bit [11:0])   mbxds;     // Mailbox for driver to monitor communication
  mailbox #(bit [11:0])   mbxms;     // Mailbox for monitor to scoreboard communication

  virtual spi_if vif;                // Virtual interface

  // Constructor
  function new(virtual spi_if vif);
    mbxgd = new();                   // Initialize mailboxes
    mbxms = new();
    mbxds = new();

    gen = new(mbxgd);                // Initialize generator
    drv = new(mbxds, mbxgd);         // Initialize driver
    mon = new(mbxms);                // Initialize monitor
    sco = new(mbxds, mbxms);         // Initialize scoreboard

    this.vif = vif;
    drv.vif  = this.vif;
    mon.vif  = this.vif;

    gen.sconext = nextgs;            // Set synchronization events
    sco.sconext = nextgs;

    gen.drvnext = nextgd;
    drv.drvnext = nextgd;
  endfunction

  // Pre-test setup
  task pre_test();
    drv.reset();                     // Perform driver reset
  endtask

  // Main test execution
  task test();
    fork
      gen.run();                     // Run generator
      drv.run();                     // Run driver
      mon.run();                     // Run monitor
      sco.run();                     // Run scoreboard
    join_any
  endtask

  // Post-test cleanup
  task post_test();
    wait(gen.done.triggered);        // Wait for generator to finish  
    $finish();
  endtask

  // Run the full test sequence
  task run();
    pre_test();
    test();
    post_test();
  endtask

endclass
`endif
