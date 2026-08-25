class alu_driver extends uvm_driver#(alu_sequence_item);
	`uvm_component_utils(alu_driver);
	virtual alu_if vif;
	alu_sequence_item item;
	function new(string name = "alu_driver",uvm_component parent = null);
		super.new(name.parent);
	endfunction
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!(uvm_config_db #(virtual alu_if)::get(this,"*","vif",vif)))
		begin
			`uvm_fatal("No VIF in the driver.")
		end
	endfunction

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		`uvm_info("DRV inside the run phase.",UVM HIGH)

		forever begin
			item=alu_sequence_item::type_id::create("item");
			seq_item_port.get_next_item(item);
			drive(item);
			seq_item_port.item_done();
		end
	endtask:run_phase

	task drive(alu_sequence_item item);
		@(posedge vif.clk);
		vif. opa<=item.opa;
    		 vif.opb<=item.opb;
		 vif.cmd<=item.cmd;
		 vif.mode<=item.mode;
		 vif.cin<=item.cin;
		 vif.inp_valid<=item.inp_valid;
		 vif.ce<=item.ce;
		 vif.rst<=item.rst;
	 endtask:drive
 endclass



