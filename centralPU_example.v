//`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module central_ex();

  reg oob, clk;
	
  //Define the constants used by the CPU
  localparam I_S = 12;
  localparam D_S = 8;
  localparam O_S = 4;
  localparam A_S = 5;
  localparam P_S = 16;
 
  //Instantiate the top level module of the centralPU design
  central #(
    .INSTR_SIZE(I_S),
    .DATA_SIZE(D_S), 
    .OPCODE_SIZE(O_S),
    .ADDR_SIZE(A_S),
    .PROGRAM_SIZE(P_S)
  ) DUT (
    .out_of_bounds(oob),
    .clk(clk)
  );
    
  initial begin
			
    clk = 0'b0;
    //Set the duration of the simulation 
    #2500 $finish;
  end 
  
  //Enable the clock and set half period
  always #10 clk = ~clk;
  
  //Pass the program to be executed to the memory.
  //In this case we start with a value (here 5), if it is non negative
  //it gets stored in Memory[16]. The starting value gets reduced by 1
  //in each iteration and if the result is non negative it gets stored
  //in Memory[16]. Once the value becomes negative the loop exits.
  initial begin
    
    DUT.mem0.internal_mem[0] = 12'b101000000101;
    DUT.mem0.internal_mem[1] = 12'b110000010001;
    DUT.mem0.internal_mem[2] = 12'b111000001110;
    DUT.mem0.internal_mem[3] = 12'b000100010001;
    DUT.mem0.internal_mem[4] = 12'b110000010000;
    DUT.mem0.internal_mem[5] = 12'b101111111111;
    DUT.mem0.internal_mem[6] = 12'b110000010001;
    DUT.mem0.internal_mem[7] = 12'b011100000000;
    DUT.mem0.internal_mem[8] = 12'b101100000001;
    DUT.mem0.internal_mem[9] = 12'b111011111010;
    DUT.mem0.internal_mem[10] = 12'b110111111001;
    DUT.mem0.internal_mem[11] = 12'b0;
    DUT.mem0.internal_mem[12] = 12'b0;
    DUT.mem0.internal_mem[13] = 12'b0;
    DUT.mem0.internal_mem[14] = 12'b0;
    DUT.mem0.internal_mem[15] = 12'b0;
  end
  
  //Create .vcd file to save signals
  initial begin
    $dumpvars;
    $dumpfile("dump.vcd");
  end
endmodule

