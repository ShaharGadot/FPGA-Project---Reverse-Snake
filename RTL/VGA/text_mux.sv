

module	text_mux	(	
		 
					
					input		logic	[10:0] DieOrWin_offsetx,
					input		logic	[10:0] DieOrWin_offsety, 
					input		logic	DieOrWinDrawingRequest,

					
					input		logic	[10:0] PressEnter_offsetx,
					input		logic	[10:0] PressEnter_offsety,
					input		logic	PressEnterDrawingRequest,

			  
					input		logic	[10:0] YourTime_offsetx,
					input		logic	[10:0] YourTime_offsety,
					input		logic	YourTimeDrawingRequest,

					
					input		logic	[10:0] HighScore_offsetx,
					input		logic	[10:0] HighScore_offsety,
					input		logic	HighScoreDrawingRequest,
			  
			  
			  
					output	logic	[10:0] TEXT_offsetx,
					output	logic	[10:0] TEXT_offsety,
					output	logic InsideRectangle,
					output	logic [2:0] TEXT

);

localparam logic [2:0]	die_or_win_line = 3'd1;
localparam logic [2:0]	press_enter = 3'd2;
localparam logic [2:0]	your_time = 3'd3;
localparam logic [2:0]	high_score = 3'd4;


always_comb begin

   TEXT_offsetx = 4'd0;
   TEXT_offsety = 4'd0;
   InsideRectangle = 1'b0;
	TEXT = 3'd0;

	if (DieOrWinDrawingRequest) begin
	
		TEXT_offsetx = DieOrWin_offsetx;
		TEXT_offsety = DieOrWin_offsety;
		InsideRectangle = DieOrWinDrawingRequest;
		TEXT = die_or_win_line;
		
	end
	else if (PressEnterDrawingRequest) begin
	
		TEXT_offsetx = PressEnter_offsetx;
		TEXT_offsety = PressEnter_offsety;
		InsideRectangle = PressEnterDrawingRequest;
		TEXT = press_enter;
		
	end
	else if (YourTimeDrawingRequest) begin
	
		TEXT_offsetx = YourTime_offsetx;
		TEXT_offsety = YourTime_offsety;
		InsideRectangle = YourTimeDrawingRequest;
		TEXT = your_time;
		
	end
	else if (HighScoreDrawingRequest) begin
	
		TEXT_offsetx = HighScore_offsetx;
		TEXT_offsety = HighScore_offsety;
		InsideRectangle = HighScoreDrawingRequest;
		TEXT = high_score;
		
	end

end

endmodule


