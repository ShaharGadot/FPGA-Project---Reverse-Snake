
module	LFSR_random	(	
					input		logic	clk,
					input		logic	resetN,
		 

			  
				   output	logic	[10:0] RandomPixelX,
				   output	logic	[10:0] RandomPixelY,
					output	logic [3:0] random_item
);

logic [9:0] registerX;
logic [8:0] registerY;
logic [6:0] register_item;// between 1 - 127

localparam logic [3:0] skull = 4'd3;
localparam logic [3:0] inverse_keys = 4'd4;
localparam logic [3:0] slow_time = 4'd5;
localparam logic [3:0] super_trap = 4'd6;

assign RandomPixelX = {1'b0 , registerX};
assign RandomPixelY = {2'b0 , registerY};


always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		registerX <= 10'b0011001010;
		registerY <= 9'b000101000;
		register_item <= 7'b0110010;

	end
	
	else begin
		registerX <= {registerX[0] ^ registerX[3] , registerX[9:1]};
		registerY <= {registerY[0] ^ registerY[4] , registerY[8:1]};
		register_item <= {register_item[0] ^ register_item[1] , register_item[6:1]};
	
	end
end	


always_comb begin 
	if(register_item < 7'd40) // 1 - 40
		random_item = skull;
	
	else if(register_item < 7'd80) // 40 - 80
		random_item = slow_time;
		
	else if(register_item < 7'd100) // 80 - 100
		random_item = inverse_keys;
		
	else
		random_item = super_trap;// 100 - 127
end

endmodule