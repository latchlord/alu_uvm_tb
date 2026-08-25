interface alu_if(input logic clk);
	logic [7:0] opa;
	logic [7:0] opb;
	logic rst;
	logic mode;
	logic cin;
	logic ce;
	logic [3:0] cmd;
	logic [1:0] inp_valid;
	logic [9:0] result;
	logic cout;
	logic oflow;
	logic g;
	logic e;
	logic l;
	logic err;

endinterface: alu_if
