`include "defines.sv"

module alu(
  input              clk,
  input              rst,
  input  [7:0]       opa,
  input  [7:0]       opb,
  input              ce,
  input              mode,
  input              cin,
  input  [3:0]       cmd,
  input  [1:0]       inp_valid,
  output reg [9:0]   res,
  output reg         cout,
  output reg         oflow,
  output reg         g,
  output reg         e,
  output reg         l,
  output reg         err
);

  reg [7:0] opa_reg, opb_reg;
  reg [2:0] rot_amt;
  reg [7:0] rot_result;

  // Input capture registers
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      opa_reg <= 8'd0;
      opb_reg <= 8'd0;
    end else if (ce) begin
      if (inp_valid[0]) opa_reg <= opa;
      if (inp_valid[1]) opb_reg <= opb;
    end
  end

  // Main ALU operation
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      res   <= 10'bz;
      cout  <= 1'bz;
      oflow <= 1'bz;
      g     <= 1'bz;
      e     <= 1'bz;
      l     <= 1'bz;
      err   <= 1'bz;
    end else if (ce) begin
      // Default outputs
      res   <= 10'd0;
      cout  <= 1'b0;
      oflow <= 1'b0;
      g     <= 1'b0;
      e     <= 1'b0;
      l     <= 1'b0;
      err   <= 1'b0;

      if (mode) begin
        // ---- ARITHMETIC (mode=1) ----
        case (cmd)
          `ADD: begin
            {cout, res[7:0]} <= opa + opb;
            res[9:8] <= 2'b00;
          end
          `SUB: begin
            res[7:0] <= opa - opb;
            res[9:8] <= 2'b00;
            oflow    <= (opa < opb) ? 1'b1 : 1'b0;
          end
          `ADD_IN: begin
            {cout, res[7:0]} <= opa + opb + cin;
            res[9:8] <= 2'b00;
          end
          `SUB_IN: begin
            res[7:0] <= opa - opb - cin;
            res[9:8] <= 2'b00;
          end
          `INC_A: begin
            res[7:0] <= opa + 8'd1;
            res[9:8] <= 2'b00;
          end
          `DEC_A: begin
            res[7:0] <= opa - 8'd1;
            res[9:8] <= 2'b00;
          end
          `INC_B: begin
            res[7:0] <= opb + 8'd1;
            res[9:8] <= 2'b00;
          end
          `DEC_B: begin
            res[7:0] <= opb - 8'd1;
            res[9:8] <= 2'b00;
          end
          `CMP: begin
            g <= (opa > opb);
            e <= (opa == opb);
            l <= (opa < opb);
          end
          `MUL_IN: begin
            res <= opa * opb;
          end
          `MUL_S: begin
            res <= opa * opb;
          end
          default: begin
            res <= 10'd0;
          end
        endcase
      end else begin
        // ---- LOGICAL (mode=0) ----
        case (cmd)
          `AND: begin
            res <= {2'b00, opa & opb};
          end
          `NAND: begin
            res <= {2'b00, ~(opa & opb)};
          end
          `OR: begin
            res <= {2'b00, opa | opb};
          end
          `NOR: begin
            res <= {2'b00, ~(opa | opb)};
          end
          `XOR: begin
            res <= {2'b00, opa ^ opb};
          end
          `XNOR: begin
            res <= {2'b00, ~(opa ^ opb)};
          end
          `NOT_A: begin
            res <= {2'b00, ~opa};
          end
          `NOT_B: begin
            res <= {2'b00, ~opb};
          end
          `SHR1_A: begin
            res <= {2'b00, opa >> 1};
          end
          `SHL1_A: begin
            res <= {2'b00, opa << 1};
          end
          `SHR1_B: begin
            res <= {2'b00, opb >> 1};
          end
          `SHL1_B: begin
            res <= {2'b00, opb << 1};
          end
          `ROL: begin
            rot_amt    = opb[2:0];
            rot_result = (opa << rot_amt) | (opa >> (8 - rot_amt));
            res <= {2'b00, rot_result};
            err <= (opb[7:4] != 4'd0) ? 1'b1 : 1'b0;
          end
          `ROR: begin
            rot_amt    = opb[2:0];
            rot_result = (opa >> rot_amt) | (opa << (8 - rot_amt));
            res <= {2'b00, rot_result};
            err <= (opb[7:4] != 4'd0) ? 1'b1 : 1'b0;
          end
          default: begin
            res <= 10'd0;
          end
        endcase
      end
    end
  end

endmodule
