//-- feb 2021 add all colors square 
// (c) Technion IIT, Department of Electrical Engineering 2025


module	back_ground_draw	(	

					input	logic	clk,
					input	logic	resetN,
					input 	logic	[10:0]	pixelX,
					input 	logic	[10:0]	pixelY,
					input 	logic	[18:0]	address,
					input		logic [2:0] 	GAME_STATE,
 
					output	logic	[7:0] 	BackGroundRGB
);




localparam  logic [9:0] TILE_NUMBER_OF_X_BITS = 6;  // 2^6 = 64  every object 
localparam  logic [9:0] TILE_NUMBER_OF_Y_BITS = 6;  // 2^6 = 64 

localparam  int MAZE_NUMBER_OF__X_BITS = 4;  // need 10 so 2^4 = 16 / /the maze of the objects 
localparam  int MAZE_NUMBER_OF__Y_BITS = 3;  // need 7.5 so 2^3 = 8 //dimentions of maze

localparam  logic [9:0] TILE_WIDTH_X = 10'b1 << TILE_NUMBER_OF_X_BITS ;//64   calc dimentions
localparam  logic [9:0] TILE_HEIGHT_Y = 10'b1 <<  TILE_NUMBER_OF_Y_BITS ;//64
localparam  logic [10:0] MAZE_WIDTH_X = 11'b1 << MAZE_NUMBER_OF__X_BITS ;//16
localparam  logic [10:0] MAZE_HEIGHT_Y = 11'b1 << MAZE_NUMBER_OF__Y_BITS ;//8


logic [7:0] OpeningRGB;
logic [7:0] FirstLevelRGB;
logic [7:0] SecondLevelRGB;
logic [7:0] FailureRGB;

logic [3:0] object;
logic [13:0] first_level_address  ;
logic [12:0] second_level_address  ;
logic [14:0] failure_address  ;

logic [7:0]  next_BackGroundRGB;

logic [5:0] offsetX_LSB;
logic [5:0] offsetY_LSB; 
logic [4:0] offsetX_MSB;
logic [4:0] offsetY_MSB;
 
assign offsetX_LSB  = pixelX[(TILE_NUMBER_OF_X_BITS-1):0] ; // get lower bits 
assign offsetY_LSB  = pixelY[(TILE_NUMBER_OF_Y_BITS-1):0] ; // get lower bits 
assign offsetX_MSB  = pixelX[10:TILE_NUMBER_OF_X_BITS] ; // get higher bits 
assign offsetY_MSB  = pixelY[10:TILE_NUMBER_OF_Y_BITS] ; // get higher bits 

assign object = MazeBitMapMask[offsetY_MSB][offsetX_MSB]; // crnt object wer'e on
assign first_level_address = (object) * 64 * 64 + (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);
assign second_level_address = (object) * 64 * 64 + (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);
assign failure_address = (object) * 64 * 64 + (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);


logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]  MazeBitMapMask ;  

logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]   FirstLevelBitMapMask= // defult table to load on reset
{
    
    {64'h2121111212_000000},
    {64'h1111111111_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000}
};

logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]   SecondLevelBitMapMask= // defult table to load on reset
{
    
    {64'h1111111111_000000},
    {64'h1111111111_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000}
};

logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]   FailureBitMapMask= // defult table to load on reset
{
    
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000120000_000000},
    {64'h0000340000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000},
    {64'h0000000000_000000}
};

logic [2:0] CURRENT_STATE;
localparam logic [2:0] OPENING_ST = 3'd0;
localparam logic [2:0] FIRST_LEVEL_ST = 3'd1;
localparam logic [2:0] SECOND_LEVEL_ST = 3'd2;
localparam logic [2:0] VICTORY_ST = 3'd3;
localparam logic [2:0] FAILURE_ST = 3'd4;

assign CURRENT_STATE = GAME_STATE;


 lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(19),
	 .LPM_NUMWORDS(307200),
    .LPM_FILE("RTL/OpeningBG.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) opening_rom_inst (
    .address(address),
	 .inclock(clk),
	// .outclock(clk),
    .q(OpeningRGB)
);

 lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(14),
	 .LPM_NUMWORDS(12288),
    .LPM_FILE("RTL/FirstLevelBG.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) first_level_rom_inst (
    .address(first_level_address),
	 .inclock(clk),
	// .outclock(clk),
    .q(FirstLevelRGB)
);

 lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(13),
	 .LPM_NUMWORDS(8192),
    .LPM_FILE("RTL/SecondLevelBG.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) second_level_rom_inst (
    .address(second_level_address),
	 .inclock(clk),
	// .outclock(clk),
    .q(SecondLevelRGB)
);

 lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(15),
	 .LPM_NUMWORDS(20480),
    .LPM_FILE("RTL/FailureBG.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) failure_rom_inst (
    .address(failure_address),
	 .inclock(clk),
	// .outclock(clk),
    .q(FailureRGB)
);



always_comb begin
	case (CURRENT_STATE)
	
		OPENING_ST : begin
			next_BackGroundRGB = OpeningRGB;
		end
		
		FIRST_LEVEL_ST: begin
			next_BackGroundRGB = FirstLevelRGB;
			MazeBitMapMask = FirstLevelBitMapMask;
		end
		
		SECOND_LEVEL_ST: begin
			next_BackGroundRGB = SecondLevelRGB;
			MazeBitMapMask = SecondLevelBitMapMask;
		end
		
		VICTORY_ST: begin
			next_BackGroundRGB = SecondLevelRGB;
			MazeBitMapMask = SecondLevelBitMapMask;
		end
		
		FAILURE_ST: begin   
			next_BackGroundRGB = FailureRGB;
			MazeBitMapMask = FailureBitMapMask;
		end
		  
		default: begin 
			next_BackGroundRGB = OpeningRGB;
			MazeBitMapMask  =  FirstLevelBitMapMask ;  //  copy default tabel 
		end
    endcase
end

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
	
		BackGroundRGB <=	8'h00;
	end 
	else begin
		
		BackGroundRGB   <= next_BackGroundRGB;
		
	end
end 

endmodule

