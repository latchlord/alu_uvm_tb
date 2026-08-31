class alu_coverage;
  alu_sequence_item data;

  covergroup alu_cg;
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
      bins greater = {3'b1zz};
      bins equal   = {3'bz1z};
      bins less    = {3'bzz1};
    }

    // Rotate amount opb[2:0]
    ROT_AMT : coverpoint data.opb[2:0] { bins amt[] = {[0:7]}; }

    // Rotate ERR flag
    ROT_ERR : coverpoint data.err { bins no_err = {0}; bins err = {1}; }

    // Crosses
    MODE_X_CMD : cross MODE, CMD;
    CMD_X_INP  : cross CMD, INP_VALID;

  endgroup

  function new();
    alu_cg = new();
  endfunction

  function void sample(alu_sequence_item t);
    data = t;
    alu_cg.sample();
  endfunction

endclass
