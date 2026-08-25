class alu_agent extends uvm_agent;
  `uvm_component_utils(alu_agent)
  
  alu_driver drv;
  alu_monitor mon;
  alu_sequencer sqr;
  
  function new(string name = "alu_agent", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv=alu_driver::type_id::create("drv",this);
    mon=alu_monitor::type_id::create("mon",this);
    sqr=alu_sequencer::type_id::create("sqr",this);
  endfunction
  
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction : connect_phase
endclass
