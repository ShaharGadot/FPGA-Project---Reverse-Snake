//
// coding convention dudy December 2018
// (c) Technion IIT, Department of Electrical Engineering 2025
// generating a number bitmap 



module NumbersBitMap	(	
					input		logic	clk,
					input		logic	resetN,
					input		logic	[2:0] GAME_STATE,
					input    logic state_transition,


					input 	logic	[10:0] offsetX,// offset from top left  position 
					input 	logic	[10:0] offsetY,
					input		logic	InsideRectangle, //input that the pixel is within a bracket 
					input 	logic	[3:0] digit, // digit to display
					
					output	logic	drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0]		RGBout
);


localparam logic[12:0] OBJECT_WIDTH_X = 6'd16;
localparam logic[12:0] OBJECT_WIDTH_Y = 6'd32;
localparam logic[12:0] digit_area = OBJECT_WIDTH_X*OBJECT_WIDTH_Y;

// generating a number bitmap from a MIF file
logic [12:0] address  ;
logic color  ;

assign address = ((digit_area*digit)+((offsetY)*OBJECT_WIDTH_X + (offsetX))); //Original size of digit
//assign address = ((digit_area*GAME_STATE)+((offsetY)*OBJECT_WIDTH_X + (offsetX))); // used for checking game states



logic	[7:0] digit_color;


logic [2:0] CURRENT_STATE;
localparam logic [2:0] OPENING_ST = 3'd0;
localparam logic [2:0] FIRST_LEVEL_ST = 3'd1;
localparam logic [2:0] SECOND_LEVEL_ST = 3'd2;
localparam logic [2:0] VICTORY_ST = 3'd3;
localparam logic [2:0] FAILURE_ST = 3'd4;

assign CURRENT_STATE = GAME_STATE;

lpm_rom #(
    .LPM_WIDTH(1),
    .LPM_WIDTHAD(13),
	 .LPM_NUMWORDS(8192),
    .LPM_FILE("RTL/numbers.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst (
    .address(address),
	 .inclock(clk),
	// .outclock(clk),
    .q(color)
);

// pipeline (ff) to get the pixel color from the array 	 

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		drawingRequest <= 1'b0;
	end
	
	else if(CURRENT_STATE == OPENING_ST || CURRENT_STATE == FAILURE_ST) begin 
		drawingRequest <= 1'b0;

	end
	
	else if (state_transition) begin // not in open or end, only before levels do once
		drawingRequest <= 1'b0;
		
	end	
	
	else begin
	
		drawingRequest <= 1'b0;
		
	  	if (InsideRectangle) begin
			if (digit == 4'hA) begin // drawing colon
				if ((offsetX > 1 && offsetX < 6) && ((offsetY > 5 && offsetY < 10) || (offsetY > 21 && offsetY < 26))) begin
					drawingRequest <= 1'b1;
				end
				else 
					drawingRequest <= 1'b0;

			end
			else 
				drawingRequest <= (color) ? 1'b1 : 1'b0;
		end
 	end 
end



always_comb begin //////////////////diferent color to digits in diferent leveld
	case (CURRENT_STATE)
	
		FIRST_LEVEL_ST: begin
			digit_color = 8'hE0;//red
		end
		
		SECOND_LEVEL_ST: begin
			digit_color = 8'hFA;//whiteish
		end
		
		VICTORY_ST: begin
			digit_color = 8'hB7;//purple-white
		end
		
		FAILURE_ST: begin
			digit_color = 8'hB7;//purple-white
		end
		
		default: begin
			digit_color = 8'hFA;//whiteish
		end
		
	endcase
end

assign RGBout = digit_color;

endmodule