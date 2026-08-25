class alu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(alu_scoreboard)

  uvm_analysis_imp #(alu_sequence_item, alu_scoreboard) scoreboard_imp;
  alu_sequence_item item_h[$];
  alu_sequence_item data;

  covergroup alu_coverage;
    option.per_instance = 1;

    // OPA / OPB value categories
    OPA : coverpoint data.opa {
      bins zero = {8'h00};
      bins one  = {8'h01};
      bins max  = {8'hFF};
      bins mid  = {[8'h02 : 8'hFE]};
    }
    OPB : coverpoint data.opb {
      bins zero = {8'h00};
      bins one  = {8'h01};
      bins max  = {8'hFF};
      bins mid  = {[8'h02 : 8'hFE]};
    }

    // MODE
    MODE : coverpoint data.mode {
      bins arith   = {1};
      bins logical = {0};
    }

    // CMD ? all 14 opcodes
    CMD : coverpoint data.cmd {
      bins add     = {4'b0000};
      bins sub     = {4'b0001};
      bins add_cin = {4'b0010};
      bins sub_cin = {4'b0011};
      bins inc_a   = {4'b0100};
      bins dec_a   = {4'b0101};
      bins inc_b   = {4'b0110};
      bins dec_b   = {4'b0111};
      bins cmp     = {4'b1000};
      bins mul_inc = {4'b1001};
      bins mul_shl = {4'b1010};
      bins shl1_b  = {4'b1011};
      bins rol_a_b = {4'b1100};
      bins ror_a_b = {4'b1101};
    }

    // INP_VALID
    INP_VALID : coverpoint data.inp_valid {
      bins capture_opa  = {2'b01};
      bins capture_opb  = {2'b10};
      bins capture_both = {2'b11};
      bins clear        = {2'b00};
    }

    // CIN, CE, RST
    CIN : coverpoint data.cin { bins cin_0 = {0}; bins cin_1 = {1}; }
    CE  : coverpoint data.ce  { bins active = {1}; bins disabled = {0}; }
    RST : coverpoint data.rst { bins active = {1}; bins inactive = {0}; }

    // Compare flags
    CMP_FLAGS : coverpoint (3'({data.g, data.e, data.l})) {
      bins greater = {3'b100};
      bins equal   = {3'b010};
      bins less    = {3'b001};
    }

    // Rotate amount opb[2:0]
    ROT_AMT : coverpoint data.opb[2:0] { bins amt[] = {[0:7]}; }

    // Rotate ERR flag
    ROT_ERR : coverpoint data.err { bins no_err = {0}; bins err = {1}; }

    // Crosses
    MODE_X_CMD : cross MODE, CMD;
    CMD_X_INP  : cross CMD, INP_VALID;

  endgroup

  function new(string name = "alu_scoreboard", uvm_component parent);
    super.new(name, parent);
    scoreboard_imp = new("scoreboard_imp", this);
    alu_coverage   = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("ALU_SB_BUILD", "INSIDE BUILD PHASE", UVM_LOW)
  endfunction

  function void write(alu_sequence_item item);
    item_h.push_back(item);
    `uvm_info("ALU_SB", "Inside write function", UVM_HIGH)
  endfunction

  task run_phase(uvm_phase phase);
    alu_sequence_item curr_trans;
    super.run_phase(phase);
    `uvm_info("ALU_SB", "INSIDE RUN PHASE", UVM_HIGH)
    forever begin
      wait(item_h.size() != 0);
      curr_trans = item_h.pop_front();
      compare(curr_trans);
    end
  endtask : run_phase

  task compare(alu_sequence_item curr_trans);

    logic [9:0] expected;
    logic [9:0] actual;
    logic       exp_cout, exp_oflow;
    logic       exp_g, exp_e, exp_l;
    logic       exp_err;
    logic [7:0] rot_result;
    logic [2:0] rot_amt;

    actual = curr_trans.res;
    data   = curr_trans;
    alu_coverage.sample();

    // ---- RST check ----
    if (curr_trans.rst) begin
      if (curr_trans.res !== 10'bz)
        `uvm_error("ALU_SB", $sformatf("RESET FAIL: RES=%0h expected=z", curr_trans.res))
      else
        `uvm_info("ALU_SB", "RESET PASS: outputs are z", UVM_LOW)
      print_coverage();
      return;
    end

    // ---- CE=0: output must not change ----
    if (!curr_trans.ce) begin
      `uvm_info("ALU_SB", "CE=0: output should be stable, no update expected", UVM_LOW)
      print_coverage();
      return;
    end

    // ---- ARITHMETIC (mode=1) ----
    if (curr_trans.mode) begin
      case (curr_trans.cmd)
        4'b0000: begin // ADD
          {exp_cout, expected[7:0]} = curr_trans.opa + curr_trans.opb;
          expected[9:8] = 0;
          if (actual[7:0] !== expected[7:0] || curr_trans.cout !== exp_cout)
            `uvm_error("ALU_SB", $sformatf("ADD FAIL: RES got=%0h exp=%0h COUT got=%0b exp=%0b",
                        actual[7:0], expected[7:0], curr_trans.cout, exp_cout))
          else
            `uvm_info("ALU_SB", $sformatf("ADD PASS: RES=%0h COUT=%0b", actual[7:0], exp_cout), UVM_LOW)
        end

        4'b0001: begin // SUB
          expected[7:0] = curr_trans.opa - curr_trans.opb;
          exp_oflow     = (curr_trans.opa < curr_trans.opb) ? 1 : 0;
          if (actual[7:0] !== expected[7:0] || curr_trans.oflow !== exp_oflow)
            `uvm_error("ALU_SB", $sformatf("SUB FAIL: RES got=%0h exp=%0h OFLOW got=%0b exp=%0b",
                        actual[7:0], expected[7:0], curr_trans.oflow, exp_oflow))
          else
            `uvm_info("ALU_SB", $sformatf("SUB PASS: RES=%0h OFLOW=%0b", actual[7:0], exp_oflow), UVM_LOW)
        end

        4'b0010: begin // ADD_CIN
          {exp_cout, expected[7:0]} = curr_trans.opa + curr_trans.opb + curr_trans.cin;
          if (actual[7:0] !== expected[7:0] || curr_trans.cout !== exp_cout)
            `uvm_error("ALU_SB", $sformatf("ADD_CIN FAIL: got=%0h exp=%0h", actual[7:0], expected[7:0]))
          else
            `uvm_info("ALU_SB", $sformatf("ADD_CIN PASS: RES=%0h", actual[7:0]), UVM_LOW)
        end

        4'b0011: begin // SUB_CIN
          expected[7:0] = curr_trans.opa - curr_trans.opb - curr_trans.cin;
          if (actual[7:0] !== expected[7:0])
            `uvm_error("ALU_SB", $sformatf("SUB_CIN FAIL: got=%0h exp=%0h", actual[7:0], expected[7:0]))
          else
            `uvm_info("ALU_SB", $sformatf("SUB_CIN PASS: RES=%0h", actual[7:0]), UVM_LOW)
        end

        4'b0100: begin // INC_A  [BUG_1: DUT may not increment]
          expected[7:0] = curr_trans.opa + 1;
          if (actual[7:0] !== expected[7:0])
            `uvm_error("ALU_SB", $sformatf("INC_A FAIL [BUG_1]: got=%0h exp=%0h", actual[7:0], expected[7:0]))
          else
            `uvm_info("ALU_SB", $sformatf("INC_A PASS: RES=%0h", actual[7:0]), UVM_LOW)
        end

        4'b0101: begin // DEC_A
          expected[7:0] = curr_trans.opa - 1;
          if (actual[7:0] !== expected[7:0])
            `uvm_error("ALU_SB", $sformatf("DEC_A FAIL: got=%0h exp=%0h", actual[7:0], expected[7:0]))
          else
            `uvm_info("ALU_SB", $sformatf("DEC_A PASS: RES=%0h", actual[7:0]), UVM_LOW)
        end

        4'b0110: begin // INC_B  [BUG_2: DUT may decrement]
          expected[7:0] = curr_trans.opb + 1;
          if (actual[7:0] !== expected[7:0])
            `uvm_error("ALU_SB", $sformatf("INC_B FAIL [BUG_2]: got=%0h exp=%0h", actual[7:0], expected[7:0]))
          else
            `uvm_info("ALU_SB", $sformatf("INC_B PASS: RES=%0h", actual[7:0]), UVM_LOW)
        end

        4'b0111: begin // DEC_B  [BUG_3: DUT may increment]
          expected[7:0] = curr_trans.opb - 1;
          if (actual[7:0] !== expected[7:0])
            `uvm_error("ALU_SB", $sformatf("DEC_B FAIL [BUG_3]: got=%0h exp=%0h", actual[7:0], expected[7:0]))
          else
            `uvm_info("ALU_SB", $sformatf("DEC_B PASS: RES=%0h", actual[7:0]), UVM_LOW)
        end

        4'b1000: begin // CMP
          exp_g = (curr_trans.opa >  curr_trans.opb);
          exp_e = (curr_trans.opa == curr_trans.opb);
          exp_l = (curr_trans.opa <  curr_trans.opb);
          if (curr_trans.g !== exp_g || curr_trans.e !== exp_e || curr_trans.l !== exp_l)
            `uvm_error("ALU_SB", $sformatf("CMP FAIL: G=%0b E=%0b L=%0b  exp G=%0b E=%0b L=%0b",
                        curr_trans.g, curr_trans.e, curr_trans.l, exp_g, exp_e, exp_l))
          else
            `uvm_info("ALU_SB", $sformatf("CMP PASS: G=%0b E=%0b L=%0b", exp_g, exp_e, exp_l), UVM_LOW)
        end

        4'b1001: `uvm_info("ALU_SB", "MUL_INC: 3-cycle op, check result after 3 cycles", UVM_LOW)
        4'b1010: `uvm_info("ALU_SB", "MUL_SHL [BUG_4]: 3-cycle op, check result after 3 cycles", UVM_LOW)

        default: `uvm_info("ALU_SB", "Unknown arithmetic CMD", UVM_MEDIUM)
      endcase

    end else begin
      // ---- LOGICAL (mode=0) ----
      case (curr_trans.cmd)
        4'b0000: begin
          expected = {2'b00, curr_trans.opa & curr_trans.opb};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("AND FAIL: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("AND PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b0001: begin
          expected = {2'b00, ~(curr_trans.opa & curr_trans.opb)};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("NAND FAIL: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("NAND PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b0010: begin // [BUG_5: DUT may use logical OR]
          expected = {2'b00, curr_trans.opa | curr_trans.opb};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("OR FAIL [BUG_5]: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("OR PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b0011: begin
          expected = {2'b00, ~(curr_trans.opa | curr_trans.opb)};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("NOR FAIL: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("NOR PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b0100: begin
          expected = {2'b00, curr_trans.opa ^ curr_trans.opb};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("XOR FAIL: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("XOR PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b0101: begin
          expected = {2'b00, ~(curr_trans.opa ^ curr_trans.opb)};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("XNOR FAIL: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("XNOR PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b0110: begin
          expected = {2'b00, ~curr_trans.opa};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("NOT_A FAIL: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("NOT_A PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b0111: begin
          expected = {2'b00, ~curr_trans.opb};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("NOT_B FAIL: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("NOT_B PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b1000: begin // [BUG_6: DUT may not shift]
          expected = {2'b00, curr_trans.opa >> 1};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("SHR1_A FAIL [BUG_6]: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("SHR1_A PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b1001: begin
          expected = {2'b00, curr_trans.opa << 1};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("SHL1_A FAIL: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("SHL1_A PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b1010: begin // [BUG_7: DUT may left-shift]
          expected = {2'b00, curr_trans.opb >> 1};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("SHR1_B FAIL [BUG_7]: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("SHR1_B PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b1011: begin
          expected = {2'b00, curr_trans.opb << 1};
          if (actual !== expected)
            `uvm_error("ALU_SB", $sformatf("SHL1_B FAIL: got=%0h exp=%0h", actual, expected))
          else `uvm_info("ALU_SB", $sformatf("SHL1_B PASS: RES=%0h", actual), UVM_LOW)
        end
        4'b1100: begin // ROL_A_B
          rot_amt    = curr_trans.opb[2:0];
          rot_result = (curr_trans.opa << rot_amt) | (curr_trans.opa >> (8 - rot_amt));
          expected   = {2'b00, rot_result};
          exp_err    = (curr_trans.opb[7:4] != 0) ? 1 : 0;
          if (actual !== expected || curr_trans.err !== exp_err)
            `uvm_error("ALU_SB", $sformatf("ROL FAIL: RES got=%0h exp=%0h ERR got=%0b exp=%0b",
                        actual, expected, curr_trans.err, exp_err))
          else `uvm_info("ALU_SB", $sformatf("ROL PASS: RES=%0h ERR=%0b", actual, exp_err), UVM_LOW)
        end
        4'b1101: begin // ROR_A_B  [BUG_8: ERR may stay 0]
          rot_amt    = curr_trans.opb[2:0];
          rot_result = (curr_trans.opa >> rot_amt) | (curr_trans.opa << (8 - rot_amt));
          expected   = {2'b00, rot_result};
          exp_err    = (curr_trans.opb[7:4] != 0) ? 1 : 0;
          if (actual !== expected || curr_trans.err !== exp_err)
            `uvm_error("ALU_SB", $sformatf("ROR FAIL [BUG_8]: RES got=%0h exp=%0h ERR got=%0b exp=%0b",
                        actual, expected, curr_trans.err, exp_err))
          else `uvm_info("ALU_SB", $sformatf("ROR PASS: RES=%0h ERR=%0b", actual, exp_err), UVM_LOW)
        end
        default: `uvm_info("ALU_SB", "Unknown logical CMD", UVM_MEDIUM)
      endcase
    end

    print_coverage();

  endtask : compare

  // -------------------------------------------------------
  // Coverage display
  // -------------------------------------------------------
  function void print_coverage();
    $display("---------------------------------------------------");
    $display("Overall Coverage    : %0.2f%%", $get_coverage());
    $display("ALU Covergroup      : %0.2f%%", alu_coverage.get_coverage());
    $display("  OPA               : %0.2f%%", alu_coverage.OPA.get_coverage());
    $display("  OPB               : %0.2f%%", alu_coverage.OPB.get_coverage());
    $display("  MODE              : %0.2f%%", alu_coverage.MODE.get_coverage());
    $display("  CMD               : %0.2f%%", alu_coverage.CMD.get_coverage());
    $display("  INP_VALID         : %0.2f%%", alu_coverage.INP_VALID.get_coverage());
    $display("  CIN               : %0.2f%%", alu_coverage.CIN.get_coverage());
    $display("  CE                : %0.2f%%", alu_coverage.CE.get_coverage());
    $display("  RST               : %0.2f%%", alu_coverage.RST.get_coverage());
    $display("  CMP_FLAGS (G/E/L) : %0.2f%%", alu_coverage.CMP_FLAGS.get_coverage());
    $display("  ROT_AMT (0-7)     : %0.2f%%", alu_coverage.ROT_AMT.get_coverage());
    $display("  ROT_ERR           : %0.2f%%", alu_coverage.ROT_ERR.get_coverage());
    $display("---------------------------------------------------");
  endfunction

endclass : alu_scoreboard
