
module	LFSR_random_pixel	(	
					input		logic	clk,
					input		logic	resetN,
		 

			  
				   output	logic	[10:0] RandomPixelX,
				   output	logic	[10:0] RandomPixelY

);

logic [9:0] registerX;
logic [8:0] registerY;

assign RandomPixelX = {1'b0 , registerX};
assign RandomPixelY = {2'b0 , registerY};


always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		registerX <= 9'b001100101;
		registerY <= 8'b00010100;

	end
	
	else begin
		registerX <= {registerX[0] ^ registerX[3] , registerX[9:1]};
		registerY <= {registerY[0] ^ registerY[4] , registerY[8:1]};

	
	end
end	
endmodule


