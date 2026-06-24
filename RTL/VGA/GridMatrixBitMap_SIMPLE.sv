// HartsMatrixBitMap File 
// A two level bitmap. dosplaying harts on the screen Feb 2025 
//(c) Technion IIT, Department of Electrical Engineering 2025 



module	GridMatrixBitMap_SIMPLE	(	
					input	logic	clk,
					input	logic	resetN,
					input logic	[10:0] offsetX,// offset from top left  position 
					input logic	[10:0] offsetY,
					input	logic	InsideRectangle, //input that the pixel is within a bracket 
					
					input logic collision_hero_trap,
					input logic collision_hero_border,
					
					input	logic	motion_clk,
					
					input logic [10:0] RandomPixelX,//from LFSR
					input logic [10:0] RandomPixelY,

					input logic [10:0] hero_X, //hero top left coardinets
               input logic [10:0] hero_Y,
					
					input logic startOfFrame,

					output	logic	[2:0] drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0] RGBout  //rgb value from the bitmap 
 ) ;
 

localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 


localparam  logic [9:0] TILE_NUMBER_OF_X_BITS = 5;  // 2^5 = 32  everu object 
localparam  logic [9:0] TILE_NUMBER_OF_Y_BITS = 5;  // 2^5 = 32 

localparam  int MAZE_NUMBER_OF__X_BITS = 5;  // need 20 so 2^5 = 32 / /the maze of the objects 
localparam  int MAZE_NUMBER_OF__Y_BITS = 4;  // need 15 so 2^4 = 16 //dimentions of maze


//-----

localparam  logic [9:0] TILE_WIDTH_X = 10'b1 << TILE_NUMBER_OF_X_BITS ;//32   calc dimentions
localparam  logic [9:0] TILE_HEIGHT_Y = 10'b1 <<  TILE_NUMBER_OF_Y_BITS ;//32
localparam  logic [10:0] MAZE_WIDTH_X = 11'b1 << MAZE_NUMBER_OF__X_BITS ;//32
localparam  logic [10:0] MAZE_HEIGHT_Y = 11'b1 << MAZE_NUMBER_OF__Y_BITS ;//16


 logic [9:0] offsetX_LSB  ;
 logic [9:0] offsetY_LSB  ; 
 logic [5:0] offsetX_MSB ;
 logic [5:0] offsetY_MSB  ;
 logic [9:0] address  ;
 logic [9:0] item_address  ;
 logic [11:0] ghost_address ;


 logic [7:0] borderColor  ;
 logic [7:0] itemColor ;
 logic [7:0] ghostColor ;
 
 logic [3:0] object_flag;//in object
 logic collision_flag;//in collision
 logic [5:0] hit_X;//coardinates of tile to erase
 logic [5:0] hit_Y;

 logic generate_trap;// on wjile generating trap
 logic [5:0] random_X_MSB;//random tile
 logic [5:0] random_Y_MSB;

 logic check_valid;//1 if in valid place
 logic in_borders;
 logic unoccupied;
 
logic [MAX_num_ghosts-1:0][5:0]  ghosts_history_X;         // Array storing X coordinates for active ghosts
logic [MAX_num_ghosts-1:0][5:0]  ghosts_history_Y;         // Array storing Y coordinates for active ghosts
logic [MAX_num_ghosts-1:0][3:0]  ghosts_history_direction; // Array storing directions for active ghosts

logic [4:0]  crnt_num_ghosts; // Counter for current number of active ghosts (0 to 20)

logic [5:0] hero_X_MSB;
logic [5:0] hero_Y_MSB;

assign hero_X_MSB  = hero_X[10:TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze
assign hero_Y_MSB  = hero_Y[10:TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
logic [5:0] hero_X_MSB_d1;
logic [5:0] hero_Y_MSB_d1;
logic [5:0] hero_X_MSB_d2;
logic [5:0] hero_Y_MSB_d2;
logic [3:0] direction_d1;
logic [3:0] direction_d2;

 assign offsetX_LSB  = offsetX[(TILE_NUMBER_OF_X_BITS-1):0] ; // get lower bits 
 assign offsetY_LSB  = offsetY[(TILE_NUMBER_OF_Y_BITS-1):0] ; // get lower bits 
 assign offsetX_MSB  = offsetX[10:TILE_NUMBER_OF_X_BITS] ; // get higher bits 
 assign offsetY_MSB  = offsetY[10:TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
 
 assign object_flag = MazeBitMapMask[offsetY_MSB][offsetX_MSB]; // crnt object wer'e on

 assign address = (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);
 assign ghost_address = (object_flag - 4'hA) * 32 * 32 + (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);
 assign item_address = (object_flag - 4'h2) * 32 * 32 + (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);

 parameter int num_ghosts = 20;
 localparam int MAX_num_ghosts = 20;



 
// the screen is 640*480  or  20 * 15 squares of 32*32  bits ,  we wiil round up to 8 *16 
// this is the bitmap  of the maze , if there is a specific value  the  whole 32*32 rectange will be drawn on the screen
// there are  16 options of differents kinds of 32*32 squares 
// all numbers here are hard coded to simplify the understanding 


logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]  MazeBitMapMask ;  

logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]   MazeDefaultBitMapMask= // defult table to load on reset
{
     
    {128'h00000000000000000000_000000000000}, // Y = 0
    {128'h00000000000000000000_000000000000}, // Y = 1
    {128'h00000000000000000000_000000000000}, // Y = 2
    {128'h11111111111111111111_000000000000}, // Y = 3
	 {128'h10000000000000000001_000000000000}, // Y = 4 
    {128'h10000000000000000001_000000000000}, // Y = 5
    {128'h10000000000000000001_000000000000}, // Y = 6
    {128'h10000000000000000001_000000000000}, // Y = 7
    {128'h10000000000000000001_000000000000}, // Y = 8
    {128'h10000000000000000001_000000000000}, // Y = 9
    {128'h10000000000000000001_000000000000}, // Y = 10
    {128'h10002000000000000001_000000000000}, // Y = 11
    {128'h10000000000000000001_000000000000}, // Y = 12
    {128'h10000000000000000001_000000000000}, // Y = 13
    {128'h11111111111111111111_000000000000}, // Y = 14
     // Y = 15: Out of screen bounds (Completely empty padding row)
    {128'h00000000000000000000_000000000000}  
};

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/border.mif"),
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
    .LPM_FILE("RTL/trap.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst2 (
    .address(item_address),
	 .inclock(clk),
	// .outclock(clk),
    .q(itemColor)
); 

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(12),
	 .LPM_NUMWORDS(4096),
    .LPM_FILE("RTL/ghost.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst3 (
    .address(ghost_address),
	 .inclock(clk),
	// .outclock(clk),
    .q(ghostColor)
); 
 

//==----------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
		MazeBitMapMask  <=  MazeDefaultBitMapMask ;  //  copy default tabel 
		
		hero_X_MSB_d1 <= hero_X_MSB;
		hero_X_MSB_d2 <= hero_X_MSB - 1'b1;
		hero_Y_MSB_d1 <= hero_Y_MSB;
		hero_Y_MSB_d2 <= hero_Y_MSB;
		direction_d1 <= 4'hB;
		direction_d2 <= 4'hB;
		
		ghosts_history_X <= '{default: 6'h0};
		ghosts_history_Y <= '{default: 6'h0};
		ghosts_history_direction <= '{default: 4'hB};
		
		crnt_num_ghosts <= 5'h0;

	end
	else begin
		RGBout <= TRANSPARENT_ENCODING ; // default 
		////////////////////////
		
		
		if(((hero_X_MSB != hero_X_MSB_d1) || (hero_Y_MSB != hero_Y_MSB_d1)) && (startOfFrame)) begin	//move ghosts	
		
			if(hero_X_MSB_d1 < hero_X_MSB)
				direction_d1 <= 4'hB;//go right
				
			else if(hero_X_MSB_d1 > hero_X_MSB)
				direction_d1 <= 4'hA;//go left
				
			else if(hero_Y_MSB_d1 < hero_Y_MSB)
				direction_d1 <= 4'hC;//go up
				
			else if(hero_Y_MSB_d1 > hero_Y_MSB)
				direction_d1 <= 4'hD;//go down
	
			hero_X_MSB_d1 <= hero_X_MSB;			 //d1 go there next clk, start of chain
			hero_Y_MSB_d1 <= hero_Y_MSB;
			
			direction_d2 <= direction_d1;//chaining
			hero_X_MSB_d2 <= hero_X_MSB_d1;
			hero_Y_MSB_d2 <= hero_Y_MSB_d1;
			
			
			ghosts_history_X <= {ghosts_history_X[MAX_num_ghosts - 2:0], hero_X_MSB_d2} ;//next position for first ghost, space between hero always 1-2 tiles
			ghosts_history_Y <= {ghosts_history_Y[MAX_num_ghosts - 2:0], hero_Y_MSB_d2} ;			
			ghosts_history_direction <= {ghosts_history_direction[MAX_num_ghosts - 2:0], direction_d2} ;
			
			if (crnt_num_ghosts >= num_ghosts) begin // not deleting when initializing snake
				MazeBitMapMask[ghosts_history_Y[crnt_num_ghosts-1]][ghosts_history_X[crnt_num_ghosts-1]] <= 4'h0;  //deleting last ghost in movement
			end 													//////maybe needs to be minus 1
			else begin
				crnt_num_ghosts <= crnt_num_ghosts + 5'h1;
			end
			MazeBitMapMask[hero_Y_MSB_d2][hero_X_MSB_d2] <= direction_d2;  //generating new ghost after hero

		
		
		end else
		
		///////////////////////////////
		if (collision_hero_trap) begin
			collision_flag <= 1'b1;
			hit_X <= offsetX_MSB;//save for deleting
			hit_Y <= offsetY_MSB;
		end
		else if (collision_flag && startOfFrame) begin
			MazeBitMapMask[hit_Y][hit_X] <= 4'h0;  // clear entry, in colision, go to the anquer calc before 
			collision_flag <= 1'b0;
			generate_trap <= 1'b1;
		end
		
		
		else if (check_valid && generate_trap) begin //place to put trap, one clk after start of frame so acceptable
			MazeBitMapMask[random_Y_MSB][random_X_MSB] <= 4'h2;  //put trap
			generate_trap <= 1'b0;
		end
		
		if (InsideRectangle == 1'b1 )	begin 
		   	case (object_flag)
					 4'h0 : RGBout <= TRANSPARENT_ENCODING ;
			   	 4'h1 : RGBout <= borderColor; 
					 4'h2 : RGBout <= itemColor ; 
					 
					 4'hA : RGBout <= ghostColor;
					 4'hB : RGBout <= ghostColor;
					 4'hC : RGBout <= ghostColor;
					 4'hD : RGBout <= ghostColor;

					 default:  RGBout <= TRANSPARENT_ENCODING ; 
				endcase
		end 

	end 
end

//==----------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest[0] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h1)) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
assign drawingRequest[1] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h2)) ? 1'b1 : 1'b0 ;
assign drawingRequest[2] = ((RGBout != TRANSPARENT_ENCODING) && ((object_flag == 4'hA) || (object_flag == 4'hB) || 
																					  (object_flag == 4'hC) || (object_flag == 4'hD))) ? 1'b1 : 1'b0 ;

assign random_X_MSB  = RandomPixelX[10:TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze
assign random_Y_MSB  = RandomPixelY[10:TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
 																		  

assign in_borders = (0 < random_X_MSB) && (4 < random_Y_MSB) && (random_Y_MSB < 15) && (random_X_MSB < 20);//between borders

assign unoccupied = (MazeBitMapMask[random_Y_MSB][random_X_MSB] == 4'h0);

assign check_valid = in_borders && unoccupied;


endmodule

