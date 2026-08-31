class alu_sequence extends uvm_sequence;
	`uvm_object_utils(alu_sequence)
	alu_sequence_item pkt;
	function new(string name = "alu_sequence");
		super.new(name);
	endfunction
	task body();
		`uvm_info("ALU_SEQ", "Inside sequence body", UVM_HIGH)
		
		// 1. Directed Test: Greater Than (G flag)
		pkt = alu_sequence_item::type_id::create("pkt");
		start_item(pkt);
		pkt.randomize() with { cmd == 4'b1000; mode == 1'b1; opa > opb; };
		finish_item(pkt);

		// 2. Directed Test: Equal (E flag)
		pkt = alu_sequence_item::type_id::create("pkt");
		start_item(pkt);
		pkt.randomize() with { cmd == 4'b1000; mode == 1'b1; opa == opb; };
		finish_item(pkt);

		// 3. Directed Test: Less Than (L flag)
		pkt = alu_sequence_item::type_id::create("pkt");
		start_item(pkt);
		pkt.randomize() with { cmd == 4'b1000; mode == 1'b1; opa < opb; };
		finish_item(pkt);

		// 4. Normal Random Test
		pkt = alu_sequence_item::type_id::create("pkt");
		start_item(pkt);
		pkt.randomize();
		finish_item(pkt);
	endtask : body

endclass : alu_sequence
