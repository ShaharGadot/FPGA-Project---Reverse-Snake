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
					
					input	logic	motion_clk,
					
					input logic [10:0] RandomPixelX,//from LFSR
					input logic [10:0] RandomPixelY,

					input logic [10:0] hero_X, //hero top left coardinets
               input logic [10:0] hero_Y,
					
					input logic startOfFrame,

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
 logic [7:0] ghostColor ;


 
 logic [4:0] MEMX;//for mif addres
 logic [4:0] MEMY;
 
 ///////////////////////////////////////////////objects and borders///////////////////
 
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
 logic [5:0] X;//for calc of random
 logic [5:0] Y;
 
 
 parameter int MAX_ghost_num = 20;
logic [MAX_ghost_num * 2 - 1:0][5:0] ghosts_history_X; //[num of gohsts *2 = num of tiles][tile]
logic [MAX_ghost_num * 2 - 1:0][5:0] ghosts_history_Y; //[num of gohsts *2 = num of tiles][tile]
logic [MAX_ghost_num * 2 - 1:0][3:0] ghosts_history_direction; //[num of ghosts][directions]

///////////////////////////////////////////////ghosts//////////////////

logic [5:0] hero_X_MSB;// hero tile
logic [5:0] hero_Y_MSB;
assign hero_X_MSB  = hero_X[(TILE_NUMBER_OF_X_BITS + MAZE_NUMBER_OF__X_BITS -1 ):TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze
assign hero_Y_MSB  = hero_Y[(TILE_NUMBER_OF_Y_BITS + MAZE_NUMBER_OF__Y_BITS -1 ):TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
 


logic [5:0] hero_X_MSB_d1;
logic [5:0] hero_Y_MSB_d1;
logic [5:0] hero_X_MSB_d2;
logic [5:0] hero_Y_MSB_d2;
logic [3:0] direction_d1;
logic [3:0] direction_d2;
logic [3:0] hero_new_direction;

logic [5:0] temp_tile_X;
logic [5:0] temp_tile_Y;
logic [3:0] temp_tile_direction;

logic [5:0] moving_ghost;
logic [4:0] crnt_num_ghosts;

logic [11:0] ghostAddress ;
logic start_of_level;

assign ghostAddress = (object_flag - 4'hA) * 32 * 32 + (MEMY * 32) + MEMX;

///////////////////////////////////grid/////////////////////////////////

 typedef struct packed {
 	 logic we;
 	 logic [5:0] y;
	 logic [5:0] x;
	 logic [3:0] data;
 } mem_req_t;

 mem_req_t grid_write_A;
 mem_req_t grid_write_B;

 
 assign offsetX_LSB  = offsetX[(TILE_NUMBER_OF_X_BITS-1):0] ; // get offset in crnt tile
 assign offsetY_LSB  = offsetY[(TILE_NUMBER_OF_Y_BITS-1):0] ; // get lower bits 
 assign offsetX_MSB  = offsetX[(TILE_NUMBER_OF_X_BITS + MAZE_NUMBER_OF__X_BITS -1 ):TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze
 assign offsetY_MSB  = offsetY[(TILE_NUMBER_OF_Y_BITS + MAZE_NUMBER_OF__Y_BITS -1 ):TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
 
 assign random_X_MSB  = RandomPixelX[(TILE_NUMBER_OF_X_BITS + MAZE_NUMBER_OF__X_BITS -1 ):TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze
 assign random_Y_MSB  = RandomPixelY[(TILE_NUMBER_OF_Y_BITS + MAZE_NUMBER_OF__Y_BITS -1 ):TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
 
 
 
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

 assign address = ( MEMY * 32) + MEMX;



 
// the screen is 640*480  or  20 * 15 squares of 32*32  bits ,  we wiil round up to 8 *16 
// this is the bitmap  of the maze , if there is a specific value  the  whole 32*32 rectange will be drawn on the screen
// there are  16 options of differents kinds of 32*32 squares 
// all numbers here are hard coded to simplify the understanding 


logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]  MazeBitMapMask ; //[32][64][4] 

logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0] MazeDefaultBitMapMask = {
													       // end of screen
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 0  top row
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 1 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 2 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 3 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 4 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 5 
    {256'h1010101010101010101010101010101010101010_000000000000000000000000}, // Y = 6 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 7 
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 8 
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 9 
    {256'h1000000000000A00000000000000000000000010_000000000000000000000000}, // Y = 10
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 11
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 12
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 13
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 14
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 15
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 16
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 17
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 18
    {256'h0000000000000000000000200000000000000000_000000000000000000000000}, // Y = 19
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 20
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 21
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 22
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 23
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 24
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 25
    {256'h1000000000000000000000000000000000000010_000000000000000000000000}, // Y = 26
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 27
    {256'h1010101010101010101010101010101010101010_000000000000000000000000}, // Y = 28
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 29 bottom row
    	     // end of screen    	     // end of screen
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}, // Y = 30
    {256'h0000000000000000000000000000000000000000_000000000000000000000000}  // Y = 31
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
    .address(address),
	 .inclock(clk),
	// .outclock(clk),
    .q(trapColor)
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
    .address(ghostAddress),
	 .inclock(clk),
	// .outclock(clk),
    .q(ghostColor)
); 

 
 
initial begin
    MazeBitMapMask = MazeDefaultBitMapMask;
	 crnt_num_ghosts = 5'h20;
end

//==----------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	8'h00;
		collision_flag <= 1'b0;
		generate_trap <= 1'b0;
		//MazeBitMapMask  <=  MazeDefaultBitMapMask ;  //  copy default tabel 
		hit_X <= 6'h0;
		hit_Y <= 6'h0;
		moving_ghost <= crnt_num_ghosts * 2 + 5'h1;
		hero_new_direction <= 4'hB;
		
		direction_d1 <= 4'hA;
		direction_d2 <= 4'hA;
		ghosts_history_direction <= '{default : 4'hA};//reset the direction pipe to right direction
		start_of_level <= 1'b1;
		
		grid_write_A <= '{we: 1'b0, y: 6'h0, x: 6'h0, data: 4'h0};
		grid_write_B <= '{we: 1'b0, y: 6'h0, x: 6'h0, data: 4'h0};

	end
	else begin
		grid_write_A.we <= 1'b0;
		grid_write_B.we <= 1'b0;

		RGBout <= TRANSPARENT_ENCODING ; // default 
		if(moving_ghost == crnt_num_ghosts * 2) // end of start
			start_of_level <= 1'b0;
		

		if(((hero_X_MSB != hero_X_MSB_d1) || (hero_Y_MSB != hero_Y_MSB_d1)) && (startOfFrame)) begin	//move ghosts	
		
			if(hero_X_MSB_d1 < hero_X_MSB)
				hero_new_direction <= 4'hB;//go right
				
			else if(hero_X_MSB_d1 > hero_X_MSB)
				hero_new_direction <= 4'hA;//go left
				
			else if(hero_Y_MSB_d1 < hero_Y_MSB)
				hero_new_direction <= 4'hD;//go up
				
			else if(hero_Y_MSB_d1 > hero_Y_MSB)
				hero_new_direction <= 4'hC;//go down
	

			hero_X_MSB_d1 <= hero_X_MSB;
			hero_Y_MSB_d1 <= hero_Y_MSB;
			direction_d1 <= hero_new_direction; //d1 go there next clk, start of chain
			
			
			hero_X_MSB_d2 <= hero_X_MSB_d1;
			hero_Y_MSB_d2 <= hero_Y_MSB_d1;
			direction_d2 <= direction_d1;//chaining
			

			//MazeBitMapMask[ghosts_history_Y[moving_ghost]][ghosts_history_X[moving_ghost]] <= 4'h0;
			grid_write_A <= '{we: 1'b1, y: ghosts_history_Y[moving_ghost], x: ghosts_history_X[moving_ghost], data: 4'h0};
			temp_tile_X <= ghosts_history_X[moving_ghost];//moving ghost = 0
			temp_tile_Y <= ghosts_history_Y[moving_ghost];
			temp_tile_direction <= ghosts_history_direction[moving_ghost];

			ghosts_history_X[moving_ghost] <= hero_X_MSB_d2;//next position for first ghost, space between hero always 1-2 tiles
			ghosts_history_Y[moving_ghost] <= hero_Y_MSB_d2;
			ghosts_history_direction[moving_ghost] <= direction_d2;

			//MazeBitMapMask[hero_Y_MSB_d2][hero_X_MSB_d2] <= direction_d2;// first ghost direction chain 
			grid_write_B <= '{we: 1'b1, y: hero_Y_MSB_d2, x: hero_X_MSB_d2, data: direction_d2};

			moving_ghost <=  6'h1;//reset "ghost and spaces" counter to 1

		end 
		else if (moving_ghost < crnt_num_ghosts * 2) begin//chain of movement
			
			if(MazeBitMapMask[ghosts_history_Y[moving_ghost]][ghosts_history_X[moving_ghost]] == 4'h0) begin// check if need to move ghost now
				//MazeBitMapMask[temp_tile_Y][temp_tile_X] <= 4'h0;//no ghost here => no ghost in next
				grid_write_A <= '{we: 1'b1, y: temp_tile_Y, x: temp_tile_X, data: 4'h0};
			end
			else begin
				//MazeBitMapMask[temp_tile_Y][temp_tile_X] <= temp_tile_direction;//ghost here, delete it and move it
				grid_write_A <= '{we: 1'b1, y: temp_tile_Y, x: temp_tile_X, data: temp_tile_direction};
				
				if(!start_of_level) 
					//MazeBitMapMask[ghosts_history_Y[moving_ghost]][ghosts_history_X[moving_ghost]] <= 4'h0;
					grid_write_B <= '{we: 1'b1, y: ghosts_history_Y[moving_ghost], x: ghosts_history_X[moving_ghost], data: 4'h0};
			end
				temp_tile_X <= ghosts_history_X[moving_ghost];//moving next ghost
				temp_tile_Y <= ghosts_history_Y[moving_ghost];
				temp_tile_direction <= ghosts_history_direction[moving_ghost];

				ghosts_history_X[moving_ghost] <= temp_tile_X;
				ghosts_history_Y[moving_ghost] <= temp_tile_Y;
				ghosts_history_direction[moving_ghost] <= temp_tile_direction;

				moving_ghost <= moving_ghost + 6'h1;
				
		end
	
		
		else if (collision_hero_trap) begin
			collision_flag <= 1'b1;
			hit_X <= offsetX_MSB - MEMX[4];//save for deleting
			hit_Y <= offsetY_MSB - MEMY[4];
		end
		else if (collision_flag && startOfFrame) begin
			//MazeBitMapMask[hit_Y][hit_X] <= 4'h0;  // clear entry, in colision, go to the anquer calc before 
			grid_write_A <= '{we: 1'b1, y: hit_Y, x: hit_X, data: 4'h0};
			collision_flag <= 1'b0;
			generate_trap <= 1'b1;
		end
		
		
		else if (check_valid && generate_trap) begin //place to put trap, one clk after start of frame so acceptable
				//MazeBitMapMask[random_Y_MSB][random_X_MSB] <= 4'h2;  //put trap
				grid_write_A <= '{we: 1'b1, y: random_Y_MSB, x: random_X_MSB, data: 4'h2};
				generate_trap <= 1'b0;
		end
		
		if (InsideRectangle == 1'b1 )	begin 
		   	case (object_flag)
					 4'h0 : RGBout <= TRANSPARENT_ENCODING ;
			   	 4'h1 : RGBout <= borderColor; 
					 4'h2 : RGBout <= trapColor ; 
					 
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

always_ff@(posedge clk)
begin

	if(grid_write_A.we) begin
		MazeBitMapMask[grid_write_A.y][grid_write_A.x] <= grid_write_A.data;
	end
	
	if(grid_write_B.we) begin
		MazeBitMapMask[grid_write_B.y][grid_write_B.x] <= grid_write_B.data;
	end

end

// decide if to draw the pixel or not 
assign drawingRequest[0] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 1)) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   
assign drawingRequest[1] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 2)) ? 1'b1 : 1'b0 ;


assign Y = random_Y_MSB;
assign X = random_X_MSB;


assign in_borders = (0 < X) && (8 < Y) && (Y < 29) && (X < 39);//between borders

assign unoccupied = (MazeBitMapMask[Y - 1][X - 1] == 4'h0) && (MazeBitMapMask[Y - 1][X] == 4'h0) && (MazeBitMapMask[Y - 1][X + 1] == 4'h0) && //check if no object in grid near
						 (MazeBitMapMask[Y][X - 1] == 4'h0) && (MazeBitMapMask[Y][X] == 4'h0) && (MazeBitMapMask[Y][X + 1] == 4'h0) &&
						 (MazeBitMapMask[Y + 1][X - 1] == 4'h0) && (MazeBitMapMask[Y + 1][X] == 4'h0) && (MazeBitMapMask[Y + 1][X + 1] == 4'h0);

assign check_valid = in_borders && unoccupied;




endmodule

