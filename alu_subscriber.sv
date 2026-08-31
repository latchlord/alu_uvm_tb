`include "uvm_macros.svh"
import uvm_pkg::*;

class alu_subscriber extends uvm_subscriber #(alu_sequence_item);
  `uvm_component_utils(alu_subscriber)

  // Instantiate the dedicated coverage class
  alu_coverage cov_obj;

  function new(string name = "alu_subscriber", uvm_component parent = null);
    super.new(name, parent);
    cov_obj = new();
  endfunction

  function void write(alu_sequence_item t);
    // Pass the transaction to the coverage collector
    cov_obj.sample(t);
  endfunction

endclass : alu_subscriber
