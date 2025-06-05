`ifndef MONITOR_SV
`define MONITOR_SV

`include "transaction.sv"
`include "interface.sv"

//===========================
// Monitor Class
//===========================
class monitor;

  transaction tr;                      // Transaction object
  mailbox #(bit [11:0]) mbx;          // Mailbox for data output
  virtual spi_if vif;                 // Virtual interface

  // Constructor
  function new(mailbox #(bit [11:0]) mbx);
    this.mbx = mbx;                   // Initialize the mailbox
  endfunction

  // Monitor execution
  task run();
    tr = new();                       // Create a new transaction
    forever begin
      @(posedge vif.sclk);
      @(posedge vif.done);
      tr.dout = vif.dout;            // Record data output
      @(posedge vif.sclk);
      $display("[MON] : DATA SENT : %0d", tr.dout);
      mbx.put(tr.dout);              // Put data in the mailbox
    end
  endtask

endclass
`endif