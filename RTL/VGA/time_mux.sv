

module	time_mux	(	
 	
					input		logic	clk,
					input		logic	resetN,
					input    logic one_sec_pulse,
					input		logic	[2:0] GAME_STATE,
					input    logic state_transition,
		 
					     
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
					output	logic	[3:0] digit,
					
					output	logic [3:0] big_min_count,
					output	logic [3:0] small_min_count,
					output	logic [3:0] big_sec_count,
					output	logic [3:0] small_sec_count

);



logic	big_sec_en;
logic small_min_en;
logic big_min_en;

logic [2:0] CURRENT_STATE;
localparam logic [2:0] OPENING_ST = 3'd0;
localparam logic [2:0] FIRST_LEVEL_ST = 3'd1;
localparam logic [2:0] SECOND_LEVEL_ST = 3'd2;
localparam logic [2:0] VICTORY_ST = 3'd3;
localparam logic [2:0] FAILURE_ST = 3'd4;

assign CURRENT_STATE = GAME_STATE;

always_comb begin

   num_offsetx = 4'd0;
   num_offsetY = 4'd0;
   digit = 4'd0;
   InsideRectangle = 1'b0;

	if (BigMinuteDrawingRequest) begin
	
		num_offsetx = BigMinute_offsetx;
		num_offsetY = BigMinute_offsetY;
		InsideRectangle = BigMinuteDrawingRequest;
		digit = big_min_count;
		
	end
	else if (SmallMinuteDrawingRequest) begin
	
		num_offsetx = SmallMinute_offsetx;
		num_offsetY = SmallMinute_offsetY;
		InsideRectangle = SmallMinuteDrawingRequest;
		digit = small_min_count;
		
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
		digit = big_sec_count;
		
	end
	else if (SmallSecondDrawingRequest) begin
	
		num_offsetx = SmallSecond_offsetx;
		num_offsetY = SmallSecond_offsetY;
		InsideRectangle = SmallSecondDrawingRequest;
		digit = small_sec_count;
		
	end

end


assign small_sec_en = one_sec_pulse;
assign big_sec_en = small_sec_en && (small_sec_count == 4'd9);
assign small_min_en = big_sec_en && (big_sec_count == 4'd5);
assign big_min_en = small_min_en && (small_min_count == 4'd9);



////////////////////////////////////////////////game counting//////////////////////////////////////////////

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		small_sec_count <= 4'd0;
		big_sec_count <= 4'd0;
		small_min_count <= 4'd0;
		big_min_count <= 4'd0;

	end
	
	else if(CURRENT_STATE == OPENING_ST || CURRENT_STATE == FAILURE_ST || CURRENT_STATE == VICTORY_ST) begin  //stop counting
		// maybe restart counter when in opening or failure state?

	end
	
	else if (state_transition && CURRENT_STATE == FIRST_LEVEL_ST) begin // restart counter before start of level 1
		small_sec_count <= 4'd0;
		big_sec_count <= 4'd0;
		small_min_count <= 4'd0;
		big_min_count <= 4'd0;
		
	end
	
	else begin
		
		if (small_sec_en) begin
			
			if (small_sec_count == 4'd9)
				small_sec_count <= 4'd0;

			else
				small_sec_count <= small_sec_count + 1'b1;
		end
		
		
		if (big_sec_en) begin
		
			if (big_sec_count == 4'd5)
				big_sec_count <= 4'd0;

			else
				big_sec_count <= big_sec_count + 1'b1;
		end
		
		
		if (small_min_en) begin
		
			if (small_min_count == 4'd9) 
				small_min_count <= 4'd0;

			else
				small_min_count <= small_min_count + 1'b1;
		end
		
		
		if (big_min_en) begin
		
			if (big_min_count == 4'd5)
				big_min_count <= 4'd0; /////////////////////////// it's been an hour, loser
				
			else
				big_min_count <= big_min_count + 1'b1;
		end
		
	
	end
end
endmodule


