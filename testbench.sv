`timescale 1ns/1ns

import uvm_pkg::*;
`include "uvm_macros.svh"

//-------------------------------------------------
//include all files
//-------------------------------------------------

`include "design.sv"
`include "alu_if.sv"
`include "alu_sequence_item.sv"
`include "alu_sequence.sv"
`include "alu_sequencer.sv"
`include "alu_driver.sv"
`include "alu_monitor.sv"
`include "alu_agent.sv"
`include "alu_scoreboard.sv"
`include "alu_subscriber.sv"
`include "alu_env.sv"
`include "alu_test.sv"


//------------------------------------------------
//ALU TOP File
//------------------------------------------------

module top;
  logic clk;
  //----------------------------------------------
  //Instantiation
  //----------------------------------------------
  
  alu_if vif(.clk(clk));
  
  alu dut(
    .clk(vif.clk),
    .rst(vif.rst),
    .opa(vif.opa),
    .opb(vif.opb),
    .ce(vif.ce),
    .mode(vif.mode),
    .cin(vif.cin),
    .cmd(vif.cmd),
    .inp_valid(vif.inp_valid),	
    .res(vif.res),
    .cout(vif.cout),
    .oflow(vif.oflow),
    .g(vif.g),
    .e(vif.e),
    .l(vif.l),
    .err(vif.err)
  );
  
  
  
  //----------------------------------------------
  //interface setting
  //----------------------------------------------
  initial begin
  uvm_config_db#(virtual alu_if)::set(null,"*","vif",vif);
  end
  
  //--------------------------------------------
  //Starting Test
  //--------------------------------------------
  initial begin
    run_test("alu_test");
  end
  
  //---------------------------------------------
  //Clock Generation
  //---------------------------------------------
  initial begin
    clk = 0;
    #5;
    forever begin
      clk = ~clk;
      #2;
    end
  end
  
  //--------------------------------------------
  //Maximum Simulation Time
  //--------------------------------------------
  initial begin
    #5000;
    $display($time,"Maximum time has reached");
    $finish;
  end
  
  
  //--------------------------------------------
  //Generate Waveforms
  //--------------------------------------------
  initial begin
    $dumpfile("test.vcd");
    $dumpvars();
  end
endmodule
