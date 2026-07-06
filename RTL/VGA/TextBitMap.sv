//
// coding convention dudy December 2018
// (c) Technion IIT, Department of Electrical Engineering 2025
// generating a number bitmap 


module TextBitMap	(
					input		logic	clk,
					input		logic	resetN,
					input 	logic	[10:0] offsetX,// offset from top left  position 
					input 	logic	[10:0] offsetY,
					input		logic [2:0] GAME_STATE,
					input		logic [2:0] TEXT,

					output	logic				TextdrawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0]		TextRGBout
);


localparam logic[12:0] OBJECT_WIDTH_X = 13'd128; // some are double, but taken care off in addres
localparam logic[12:0] OBJECT_WIDTH_Y = 13'd128;
localparam logic[12:0] MIF_area = OBJECT_WIDTH_X * OBJECT_WIDTH_Y;


localparam logic [2:0]	die_or_win_line = 3'd1;//coded like in the mux 
localparam logic [2:0]	press_enter = 3'd2;
localparam logic [2:0]	your_time = 3'd3;
localparam logic [2:0]	high_score = 3'd4;


// generating a number bitmap from a MIF file
logic [16:0] address  ;
logic [3:0]	TEXT_addres	;
logic [7:0] color  ;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 

 
assign address = (offsetX < 128) ? (MIF_area * TEXT_addres + ((offsetY)*OBJECT_WIDTH_X + (offsetX))) :
											  (MIF_area * (TEXT_addres + 1'b1) + ((offsetY)*OBJECT_WIDTH_X + (offsetX - 128)));
												////// checking if the addres is of small or large object///////

logic [2:0] CURRENT_STATE;
localparam logic [2:0] OPENING_ST = 3'd0;
localparam logic [2:0] FIRST_LEVEL_ST = 3'd1;
localparam logic [2:0] SECOND_LEVEL_ST = 3'd2;
localparam logic [2:0] VICTORY_ST = 3'd3;
localparam logic [2:0] FAILURE_ST = 3'd4;

assign CURRENT_STATE = GAME_STATE;


lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(17),
	 .LPM_NUMWORDS(131072),
    .LPM_FILE("RTL/Text.mif"),
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

/////////////////////////// calculating correct mif using state and position in sceen ///////////////////
always_comb begin

	TEXT_addres = 4'd0;

	if (CURRENT_STATE == FAILURE_ST) begin
		
		case (TEXT)
			
			die_or_win_line : TEXT_addres = 4'd0;
			press_enter : TEXT_addres = 4'd4;
			
		endcase	
	end
	
	else if (CURRENT_STATE == VICTORY_ST) begin
		
		case (TEXT)
			
			die_or_win_line : TEXT_addres = 4'd2;
			press_enter : TEXT_addres = 4'd4;
			your_time : TEXT_addres = 4'd6;
			high_score : TEXT_addres = 4'd7;
			
		endcase	
	end
	
end

/////////////////////////////// enabling color only when wanted //////////////////


always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		TextRGBout <= TRANSPARENT_ENCODING ;
	end
	
	
	else begin
		TextRGBout <= TRANSPARENT_ENCODING ; // default  
		
		if (CURRENT_STATE == FAILURE_ST && (TEXT == die_or_win_line || TEXT == press_enter))
			TextRGBout <= color;
			
			
		if (CURRENT_STATE == VICTORY_ST && (TEXT == die_or_win_line || TEXT == press_enter 
															|| TEXT == your_time || TEXT == high_score))
			TextRGBout <= color;

 	end 
end

assign TextdrawingRequest = (TextRGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule