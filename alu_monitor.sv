class alu_monitor extends uvm_monitor;
  `uvm_component_utils(alu_monitor)
  
  virtual alu_if vif;
  alu_sequence_item item;
  
  uvm_analysis_port #(alu_sequence_item) monitor_port;
  
  function new(string name = "alu_monitor", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!(uvm_config_db #(virtual alu_if)::get(this, "*", "vif", vif))) begin
      `uvm_error("ALU_MON", "INSIDE BUILD PHASE FAILED GET OF CONFIG DB")
    end
    monitor_port = new("monitor_port", this);
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    `uvm_info("ALU_MON", "INSIDE RUN PHASE", UVM_HIGH)
    
    forever begin
      item = alu_sequence_item::type_id::create("item");
      
      wait(!vif.rst);
      
      
      @(posedge vif.clk);
      item.opa = vif.opa;
      item.opb = vif.opb;
      item.ce = vif.ce;
      item.mode = vif.mode;
      item.cin = vif.cin;
      item.cmd = vif.cmd;
      item.inp_valid = vif.inp_valid;
      item.rst = vif.rst; 
      
      @(posedge vif.clk);
      item.res = vif.res;
      item.cout = vif.cout;
      item.oflow = vif.oflow;
      item.g = vif.g;
      item.e = vif.e;
      item.l = vif.l;
      item.err = vif.err;

      
      monitor_port.write(item);
    end
  endtask : run_phase
endclass
