class alu_test extends uvm_test();
  `uvm_component_utils(alu_test)
  
  alu_env env;
  alu_sequence seq;
  
  
  function new(string name = "alu_test", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env=alu_env::type_id::create("env",this);
    seq = alu_sequence::type_id::create("seq",this);
      endfunction
  
  function void start_of_simulation();
        uvm_top.print_topology();
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("ALU_TEST","INSIDE RUN PHASE",UVM_HIGH)
    
    phase.raise_objection(this);
    
    repeat(100) begin
      seq.start(env.agt.sqr);
      #10;
     end
        
    phase.drop_objection(this);
  endtask
endclass
