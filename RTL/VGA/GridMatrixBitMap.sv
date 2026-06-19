// HartsMatrixBitMap File 
// A two level bitmap. dosplaying harts on the screen Feb 2025 
//(c) Technion IIT, Department of Electrical Engineering 2025 



module	GridMatrixBitMap	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					input logic collision_hero_trap,
					input logic collision_hero_border,

					input logic [10:0] Hero_X, //hero top left coardinets
               input logic [10:0] Hero_Y,

					output	logic	[1:0] drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout  //rgb value from the bitmap 
 ) ;
 

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 


localparam  logic [9:0] TILE_NUMBER_OF_X_BITS = 4;  // 2^4 = 16  size of tile 
localparam  logic [9:0] TILE_NUMBER_OF_Y_BITS = 4;  // 2^4 = 16

localparam  int MAZE_NUMBER_OF__X_BITS = 6;  // 2^6 = 64 / /the maze of the objects 
localparam  int MAZE_NUMBER_OF__Y_BITS = 5;  // 2^5 = 32 //dimentions of maze

//-----

localparam  logic [9:0] TILE_WIDTH_X = 10'b1 << TILE_NUMBER_OF_X_BITS ;// calc dimentions
localparam  logic [9:0] TILE_HEIGHT_Y = 1'b1 <<  TILE_NUMBER_OF_Y_BITS ;
localparam  logic [10:0] MAZE_WIDTH_X = 11'b1 << MAZE_NUMBER_OF__X_BITS ;//64
localparam  logic [10:0] MAZE_HEIGHT_Y = 11'b1 << MAZE_NUMBER_OF__Y_BITS ;//32


 logic [3:0] offsetX_LSB  ;
 logic [3:0] offsetY_LSB  ; 
 logic [5:0] offsetX_MSB ;
 logic [5:0] offsetY_MSB  ;
 logic [9:0] address  ;
 
 logic [7:0] borderColor  ;
 logic [7:0] trapColor ;

 
 logic [4:0] MEMX;
 logic [4:0] MEMY;
 logic [3:0] object_flag;

 assign offsetX_LSB  = offsetX[(TILE_NUMBER_OF_X_BITS-1):0] ; // get offset in crnt tile
 assign offsetY_LSB  = offsetY[(TILE_NUMBER_OF_Y_BITS-1):0] ; // get lower bits 
 assign offsetX_MSB  = offsetX[(TILE_NUMBER_OF_X_BITS + MAZE_NUMBER_OF__X_BITS -1 ):TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze
 assign offsetY_MSB  = offsetY[(TILE_NUMBER_OF_Y_BITS + MAZE_NUMBER_OF__Y_BITS -1 ):TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
 
 
 
 always_comb begin // checking if inside object. is yes, calc where the "anquer" is and setting the memory addres accordingly
	MEMX = 5'b0;
	MEMY = 5'b0;
	object_flag = 4'h0;//inside object indicator, will store the type of object
	
	if (MazeBitMapMask[offsetY_MSB][offsetX_MSB] != 4'h0) begin
		MEMX = {1'b0, offsetX_LSB};
		MEMY = {1'b0, offsetY_LSB};
		object_flag = MazeBitMapMask[offsetY_MSB][offsetX_MSB];
	end
	else if ((offsetX_MSB > 0) && (MazeBitMapMask[offsetY_MSB][offsetX_MSB - 1] != 4'h0)) begin
		MEMX = {1'b1, offsetX_LSB};
		MEMY = {1'b0, offsetY_LSB};
		object_flag = MazeBitMapMask[offsetY_MSB][offsetX_MSB - 1];
	end
	else if ((offsetY_MSB > 0) && (MazeBitMapMask[offsetY_MSB - 1][offsetX_MSB] != 4'h0)) begin
		MEMX = {1'b0, offsetX_LSB};
		MEMY = {1'b1, offsetY_LSB};
		object_flag = MazeBitMapMask[offsetY_MSB - 1][offsetX_MSB];
	end
	else if ((offsetX_MSB > 0) && (offsetY_MSB > 0) && (MazeBitMapMask[offsetY_MSB - 1][offsetX_MSB - 1] != 4'h0)) begin
		MEMX = {1'b1, offsetX_LSB};
		MEMY = {1'b1, offsetY_LSB};
		object_flag = MazeBitMapMask[offsetY_MSB - 1][offsetX_MSB - 1];
	end
	
 end

 assign address = (MEMY * 32) + MEMX;



 
// the screen is 640*480  or  20 * 15 squares of 32*32  bits ,  we wiil round up to 8 *16 
// this is the bitmap  of the maze , if there is a specific value  the  whole 32*32 rectange will be drawn on the screen
// there are  16 options of differents kinds of 32*32 squares 
// all numbers here are hard coded to simplify the understanding 


logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]  MazeBitMapMask ; //[32][64][4] 

logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0] MazeDefaultBitMapMask = {
													       // end of screen
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 0  top row
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 1 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 2 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 3 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 4 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 5 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 6 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 7 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 8 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 9 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 10
    {256'h0000000200000000000000000000000000000000_000000000000000000000000}, // Y = 11
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 12
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 13
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 14
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 15
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 16
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 17
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 18
    {256'h0000000000000000000000200000000000000000_000000000000000000000000}, // Y = 19
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 20
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 21
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 22
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 23
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 24
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 25
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 26
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 27
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 28
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 29 bottom row
    	     // end of screen    	     // end of screen
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 30
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}  // Y = 31
};
 
 
 
 
 
 lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/heart1.mif"),
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
    .q(borderColor)
);

 
lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/heart2.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst2 (
    .address(address),
	 .inclock(clk),
	// .outclock(clk),
    .q(trapColor)
); 

 

//==----------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
		MazeBitMapMask  <=  MazeDefaultBitMapMask ;  //  copy default tabel 
	end
	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default 
		if (collision_hero_trap)begin
				MazeBitMapMask[offsetY_MSB - MEMY[4]][offsetX_MSB - MEMX[4]] <= 4'h0;  // clear entry, in colision, go to the anquer calc before 
		end
		if (InsideRectangle == 1'b1 )	begin 
		   	case (object_flag)
					 4'h0 : RGBout <= TRANSPARENT_ENCODING ;
			   	 4'h1 : RGBout <= borderColor; 
					 4'h2 : RGBout <= trapColor ; 
					 default:  RGBout <= TRANSPARENT_ENCODING ; 
				endcase
		end 

	end 
end

//==----------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest[0] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 1)) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
assign drawingRequest[1] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 2)) ? 1'b1 : 1'b0 ;
endmodule

