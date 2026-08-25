class alu_sequence extends uvm_sequence;
	`uvm_object_utils(alu_sequence)
	alu_sequence_item pkt;
	function new(string name = "alu_sequence");
		super.new(name);
	endfunction
	task body();
		`uvm_info("Inside sequence body",UVM HIGH)
		pkt=alu_sequence_item::type_id::create("pkt");
		start_item(pkt);
		pkt.randomize();
		finish_item(pkt);
	endtask:body

endclass:alu_sequence
		

