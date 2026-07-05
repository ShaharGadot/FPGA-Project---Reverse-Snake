

module GreenBarBitMap	(	
					input		logic	clk,
					input		logic	resetN,
					input 	logic	[10:0] offsetX,
					input 	logic	[10:0] offsetY,
					input		logic	InsideRectangle, 
					
					input    logic [4:0] num_ghosts,
					input    logic [4:0] max_num_ghosts,

					input		logic [2:0] GAME_STATE,
					
					output	logic	drawingRequest,
					output	logic	[7:0]	RGBout
);


localparam int OBJECT_WIDTH_X = 250;
localparam int OBJECT_WIDTH_Y = 32;


logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;
logic [7:0] shaded_green;
logic [7:0] BORDERCOLOR = 8'hFA; // black?

int internal_height;
assign internal_height = OBJECT_WIDTH_Y - 10;

always_comb begin 
		 
	int relative_y;

   shaded_green = 8'b000_100_00; 
	relative_y = 0;

	if (offsetY >= 5 && offsetY < (OBJECT_WIDTH_Y - 5)) begin // check if inside bar's 
       
		relative_y = offsetY - 5;
        
		if      (relative_y < (internal_height * 1) / 7) shaded_green = 8'b000_111_00; // gradient of green from top (lighest green)
      else if (relative_y < (internal_height * 2) / 7) shaded_green = 8'b000_110_00; 
      else if (relative_y < (internal_height * 3) / 7) shaded_green = 8'b000_101_00; 
      else if (relative_y < (internal_height * 4) / 7) shaded_green = 8'b000_100_00; 
      else if (relative_y < (internal_height * 5) / 7) shaded_green = 8'b000_011_00; 
      else if (relative_y < (internal_height * 6) / 7) shaded_green = 8'b000_010_00; 
      else                                             shaded_green = 8'b000_001_00; // to bottom (darkest)
		
	end
end

logic [15:0] green_zone_limit;
assign green_zone_limit = ((OBJECT_WIDTH_X - 10) * 16'd1 * num_ghosts) / 16'(max_num_ghosts); // how much of the bar is green


logic [2:0] CURRENT_STATE;
localparam logic [2:0] OPENING_ST = 3'd0;
localparam logic [2:0] FIRST_LEVEL_ST = 3'd1;
localparam logic [2:0] SECOND_LEVEL_ST = 3'd2;
localparam logic [2:0] VICTORY_ST = 3'd3;
localparam logic [2:0] FAILURE_ST = 3'd4;

assign CURRENT_STATE = GAME_STATE;

// pipeline (ff) to get the pixel color from the array 	 

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <= TRANSPARENT_ENCODING ;
	end
	
	else if (CURRENT_STATE == OPENING_ST || CURRENT_STATE == FAILURE_ST) begin
		RGBout <= TRANSPARENT_ENCODING ;
		//wait for start of level
	end
	
	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default  

	  	if (InsideRectangle) begin
			if (offsetX < 11'd5 || offsetX > (OBJECT_WIDTH_X - 5) || 
				 offsetY < 11'd5 || offsetY > (OBJECT_WIDTH_Y - 5)) // inside borders 
				RGBout <= BORDERCOLOR;
			
			else if (offsetX < (11'd5 + green_zone_limit[10:0])) // inside green relative erea
				RGBout <= shaded_green;
			
			else begin
				RGBout <= TRANSPARENT_ENCODING ; //

			end
		end
 	end 
end

assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule