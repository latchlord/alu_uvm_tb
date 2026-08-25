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

  reg [7:0] oprd1, oprd2;
  reg [2:0] rot_amt;
  reg [7:0] rot_result;

  // Input capture stage based on INP_VALID
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      oprd1 <= 8'd0;
      oprd2 <= 8'd0;
    end else if (ce) begin
      case (inp_valid)
        2'b01: oprd1 <= opa;
        2'b10: oprd2 <= opb;
        2'b11: begin
          oprd1 <= opa;
          oprd2 <= opb;
        end
        default: begin  // 2'b00 - clear captured operands
          oprd1 <= 8'd0;
          oprd2 <= 8'd0;
        end
      endcase
    end
  end

  // Execution stage - operations on posedge CLK when CE=1, RST=0
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
      g     <= 1'bz;
      e     <= 1'bz;
      l     <= 1'bz;
      err   <= 1'b0;

      if (mode) begin
        // ---- ARITHMETIC (mode=1) ----
        case (cmd)
          `ADD: begin
            {cout, res[7:0]} <= oprd1 + oprd2;
            res[9:8] <= 2'b00;
          end
          `SUB: begin
            res[7:0] <= oprd1 - oprd2;
            res[9:8] <= 2'b00;
            oflow    <= (oprd1 < oprd2) ? 1'b1 : 1'b0;
          end
          `ADD_IN: begin
            {cout, res[7:0]} <= oprd1 + oprd2 + cin;
            res[9:8] <= 2'b00;
          end
          `SUB_IN: begin
            res[7:0] <= oprd1 - oprd2 - cin;
            res[9:8] <= 2'b00;
            oflow    <= (oprd1 < oprd2) ? 1'b1 : 1'b0;
          end

          // BUG_1: INC_A performs no increment (should be oprd1 + 1)
          `INC_A: begin
            res[7:0] <= oprd1;          // BUG: missing + 1
            res[9:8] <= 2'b00;
          end

          `DEC_A: begin
            res[7:0] <= oprd1 - 8'd1;
            res[9:8] <= 2'b00;
          end

          // BUG_2: INC_B performs decrement instead of increment
          `INC_B: begin
            res[7:0] <= oprd2 - 8'd1;   // BUG: should be + 1
            res[9:8] <= 2'b00;
          end

          // BUG_3: DEC_B performs increment instead of decrement
          `DEC_B: begin
            res[7:0] <= oprd2 + 8'd1;   // BUG: should be - 1
            res[9:8] <= 2'b00;
          end

          `CMP: begin
            // Non-active flags set to 1'bz per spec
            if (oprd1 > oprd2) begin
              g <= 1'b1; e <= 1'bz; l <= 1'bz;
            end else if (oprd1 == oprd2) begin
              g <= 1'bz; e <= 1'b1; l <= 1'bz;
            end else begin
              g <= 1'bz; e <= 1'bz; l <= 1'b1;
            end
          end

          `MUL_IN: begin
            res <= oprd1 * oprd2;
          end

          // BUG_4: MUL_SHL performs subtraction instead of multiplication
          `MUL_S: begin
            res <= oprd1 - oprd2;        // BUG: should be multiplication
          end

          default: begin
            res <= 10'd0;
          end
        endcase
      end else begin
        // ---- LOGICAL (mode=0) ----
        case (cmd)
          `AND: begin
            res <= {2'b00, oprd1 & oprd2};
          end
          `NAND: begin
            res <= {2'b00, ~(oprd1 & oprd2)};
          end

          // BUG_5: OR uses AND instead of bitwise OR
          `OR: begin
            res <= {2'b00, oprd1 & oprd2};  // BUG: should be |
          end

          `NOR: begin
            res <= {2'b00, ~(oprd1 | oprd2)};
          end
          `XOR: begin
            res <= {2'b00, oprd1 ^ oprd2};
          end
          `XNOR: begin
            res <= {2'b00, ~(oprd1 ^ oprd2)};
          end
          `NOT_A: begin
            res <= {2'b00, ~oprd1};
          end
          `NOT_B: begin
            res <= {2'b00, ~oprd2};
          end

          // BUG_6: SHR1_A performs no shift (returns oprd1 as-is)
          `SHR1_A: begin
            res <= {2'b00, oprd1};           // BUG: should be oprd1 >> 1
          end

          `SHL1_A: begin
            res <= {2'b00, oprd1 << 1};
          end

          // BUG_7: SHR1_B performs left shift instead of right shift
          `SHR1_B: begin
            res <= {2'b00, oprd2 << 1};      // BUG: should be oprd2 >> 1
          end

          `SHL1_B: begin
            res <= {2'b00, oprd2 << 1};
          end

          `ROL: begin
            rot_amt    = oprd2[2:0];
            rot_result = (oprd1 << rot_amt) | (oprd1 >> (8 - rot_amt));
            res <= {2'b00, rot_result};
            err <= (oprd2[7:4] != 4'd0) ? 1'b1 : 1'b0;
          end

          // BUG_8: ROR_A_B sets ERR=0 instead of 1 on error condition
          `ROR: begin
            rot_amt    = oprd2[2:0];
            rot_result = (oprd1 >> rot_amt) | (oprd1 << (8 - rot_amt));
            res <= {2'b00, rot_result};
            err <= 1'b0;                     // BUG: should check oprd2[7:4]
          end

          default: begin
            res <= 10'd0;
          end
        endcase
      end
    end
  end

endmodule
