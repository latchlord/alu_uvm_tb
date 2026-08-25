`include "defines.sv"

class alu_sequence_item extends uvm_sequence_item;

    	  rand logic [7:0] opa;           
    	  rand logic [7:0] opb;           
    	  rand logic [3:0] cmd;           
   	  rand logic       mode;         
   	  rand logic       cin;           
   	  rand logic [1:0] inp_valid;     
   	  rand logic       ce;            
   	  rand logic       rst;           
   
    	  logic [9:0] res;        
    	  logic       cout;       
    	  logic       oflow;      
     	  logic       g;          
    	  logic       e;          
    	  logic       l;          
    	  logic       err;

	  constraint ce_bias       { ce        dist {1 := 90, 0 := 10}; }
	  constraint rst_bias      { rst       dist {0 := 95, 1 := 5};  }
	  constraint inp_valid_c   { inp_valid == 2'b11; }

         `uvm_object_utils_begin(alu_sequence_item)
	 `uvm_field_int(opa,       UVM_ALL_ON)
 	 `uvm_field_int(opb,       UVM_ALL_ON)
 	 `uvm_field_int(cmd,       UVM_ALL_ON)
 	 `uvm_field_int(mode,      UVM_ALL_ON)
 	 `uvm_field_int(cin,       UVM_ALL_ON)
 	 `uvm_field_int(inp_valid, UVM_ALL_ON)
 	 `uvm_field_int(ce,        UVM_ALL_ON)
 	 `uvm_field_int(rst,       UVM_ALL_ON)
 	 `uvm_field_int(res,       UVM_ALL_ON)
 	 `uvm_field_int(cout,      UVM_ALL_ON)
 	 `uvm_field_int(oflow,     UVM_ALL_ON)
 	 `uvm_field_int(g,         UVM_ALL_ON)
 	 `uvm_field_int(e,         UVM_ALL_ON)
 	 `uvm_field_int(l,         UVM_ALL_ON)
 	 `uvm_field_int(err,       UVM_ALL_ON)
 	 `uvm_object_utils_end

	  function new(string name = "alu_sequence_item");
		  super.new(name);
	  endfunction

  endclass
