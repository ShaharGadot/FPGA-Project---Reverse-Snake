

module	high_score_mux	(	
					
					input		logic	[2:0] GAME_STATE,

					input 	logic [3:0] big_min_HS,
					input 	logic [3:0] small_min_HS,
					input 	logic [3:0] big_sec_HS,
					input 	logic [3:0] small_sec_HS,
		 
					     
					input		logic	[10:0] BigMinute_offsetx,
					input		logic	[10:0] BigMinute_offsetY,
					input		logic	BigMinuteDrawingRequest,

					
					input		logic	[10:0] SmallMinute_offsetx,
					input		logic	[10:0] SmallMinute_offsetY, 
					input		logic	SmallMinuteDrawingRequest,

					
					input		logic	[10:0] Colon_offsetx,
					input		logic	[10:0] Colon_offsetY,
					input		logic	ColonDrawingRequest,

			  
					input		logic	[10:0] BigSecond_offsetx,
					input		logic	[10:0] BigSecond_offsetY,
					input		logic	BigSecondDrawingRequest,

					
					input		logic	[10:0] SmallSecond_offsetx,
					input		logic	[10:0] SmallSecond_offsetY,
					input		logic	SmallSecondDrawingRequest,
			  
			  
			  
			  
			  
					output	logic	[10:0] num_offsetx,
					output	logic	[10:0] num_offsetY,
					output	logic InsideRectangle,
					output	logic	[3:0] digit

);


logic [2:0] CURRENT_STATE;
localparam logic [2:0] OPENING_ST = 3'd0;
localparam logic [2:0] FIRST_LEVEL_ST = 3'd1;
localparam logic [2:0] SECOND_LEVEL_ST = 3'd2;
localparam logic [2:0] THIRD_LEVEL_ST = 3'd3;
localparam logic [2:0] VICTORY_ST = 3'd4;
localparam logic [2:0] FAILURE_ST = 3'd5;

assign CURRENT_STATE = GAME_STATE;



always_comb begin

   num_offsetx = 4'd0;
   num_offsetY = 4'd0;
   digit = 4'd0;
   InsideRectangle = 1'b0;
	
	if (CURRENT_STATE == VICTORY_ST) begin
	
		if (BigMinuteDrawingRequest) begin
		
			num_offsetx = BigMinute_offsetx;
			num_offsetY = BigMinute_offsetY;
			InsideRectangle = BigMinuteDrawingRequest;
			digit = big_min_HS;
			
		end
		else if (SmallMinuteDrawingRequest) begin
		
			num_offsetx = SmallMinute_offsetx;
			num_offsetY = SmallMinute_offsetY;
			InsideRectangle = SmallMinuteDrawingRequest;
			digit = small_min_HS;
			
		end
		else if (ColonDrawingRequest) begin
		
			num_offsetx = Colon_offsetx;
			num_offsetY = Colon_offsetY;
			InsideRectangle = ColonDrawingRequest;
			digit = 4'hA;
			
		end
		else if (BigSecondDrawingRequest) begin
		
			num_offsetx = BigSecond_offsetx;
			num_offsetY = BigSecond_offsetY;
			InsideRectangle = BigSecondDrawingRequest;
			digit = big_sec_HS;
			
		end
		else if (SmallSecondDrawingRequest) begin
		
			num_offsetx = SmallSecond_offsetx;
			num_offsetY = SmallSecond_offsetY;
			InsideRectangle = SmallSecondDrawingRequest;
			digit = small_sec_HS;
			
		end
		
	end

end

endmodule


