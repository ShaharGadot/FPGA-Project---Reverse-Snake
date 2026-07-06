//
// coding convention dudy December 2018
// (c) Technion IIT, Department of Electrical Engineering 2025
// generating a number bitmap 



module HeroBitMap	(	
					input		logic	clk,
					input		logic	resetN,
					input 	logic	[10:0] offsetX,// offset from top left  position 
					input 	logic	[10:0] offsetY,
					input		logic	InsideRectangle, //input that the pixel is within a bracket 
					input 	logic	[3:0] digit, // digit to display
					input    logic motion_clk,
					input		logic [2:0] GAME_STATE,
					
					output	logic				drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0]		RGBout
);


localparam logic[12:0] OBJECT_WIDTH_X = 6'd32;
localparam logic[12:0] OBJECT_WIDTH_Y = 6'd32;
localparam logic[12:0] MIF_area = OBJECT_WIDTH_X*OBJECT_WIDTH_Y;

// generating a number bitmap from a MIF file
logic [12:0] address  ;
logic [7:0] color  ;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 

 
assign address = ((MIF_area*(digit + motion_clk))+((offsetY)*OBJECT_WIDTH_X + (offsetX))); //Origimal size of digit


parameter  logic	[7:0] digit_color = 8'hff ; //set the color of the digit


logic [2:0] CURRENT_STATE;
localparam logic [2:0] OPENING_ST = 3'd0;
localparam logic [2:0] FIRST_LEVEL_ST = 3'd1;
localparam logic [2:0] SECOND_LEVEL_ST = 3'd2;
localparam logic [2:0] THIRD_LEVEL_ST = 3'd3;
localparam logic [2:0] VICTORY_ST = 3'd4;
localparam logic [2:0] FAILURE_ST = 3'd5;

assign CURRENT_STATE = GAME_STATE;


lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(13),
	 .LPM_NUMWORDS(8192),
    .LPM_FILE("RTL/hero.mif"),
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
		RGBout <= TRANSPARENT_ENCODING ;
	end

	else if (CURRENT_STATE == OPENING_ST || CURRENT_STATE == FAILURE_ST || CURRENT_STATE == VICTORY_ST) begin
	
		//wait for start of level
		RGBout <= TRANSPARENT_ENCODING ; 
	end
	
	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default  

	  	if (InsideRectangle == 1'b1 ) begin
			RGBout <= color;
		end
 	end 
end

assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule