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
					input logic collision_hero_skull,
					input logic collision_hero_inverse_keys_pd,
					input logic collision_hero_slow_time_pu,
					input logic collision_hero_super_trap_pu,
					input logic [3:0] random_item,
								
					input logic [2:0] GAME_STATE,
					input logic open_sesame,
					input logic state_transition,
					
					input logic motion_pulse,

					
					input logic [10:0] RandomPixelX,//from LFSR
					input logic [10:0] RandomPixelY,

					input logic [10:0] hero_X, //hero top left coardinets
               input logic [10:0] hero_Y,
			      input logic [10:0] hero_initial_X,
               input logic [10:0] hero_initial_Y,

					
					input logic startOfFrame,
					
					
					output logic [4:0] max_num_ghosts,
					output logic [4:0] num_ghosts,
					output logic	[8:0] drawingRequest, //output that the pixel should be dispalyed 
					output logic	[7:0] RGBout  //rgb value from the bitmap 
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
 logic [10:0] border_address  ;
 logic [12:0] item_address  ;
 logic [12:0] ghost_address ;
 logic [10:0] grave_address  ;



 logic [7:0] borderColor  ;
 logic [7:0] itemColor ;
 logic [7:0] ghostColor ;
 logic [7:0] graveColor ;

 
 logic collision_pwr_item;
 logic [3:0] object_flag;//in object
 logic [1:0] border_type;
 logic collision_trap_flag;//in collision
 logic collision_skull_flag;//in collision
 logic collision_passive_item_flag;//in collision with pwr item that dosent affect grid
 logic collision_super_trap_flag;

 logic [5:0] hit_X;//coardinates of tile to erase
 logic [5:0] hit_Y;

 logic switch_grave_pos;// on while moving grave
 logic generate_trap;// on while generating trap
 logic generate_pwr_item;// on while generating pwr item
 logic [5:0] random_X_MSB;//random tile
 logic [5:0] random_Y_MSB;
 
 logic [5:0] grave_X;
 logic [5:0] grave_Y;

 logic check_random_valid;//1 if in valid place
 logic in_borders;
 logic unoccupied;
 
logic [MAX_num_ghosts-1:0][5:0]  ghosts_history_X;         // Array storing X coordinates for active ghosts
logic [MAX_num_ghosts-1:0][5:0]  ghosts_history_Y;         // Array storing Y coordinates for active ghosts
logic [MAX_num_ghosts-1:0][3:0]  ghosts_history_direction; // Array storing directions for active ghosts

logic [5:0] explosionX;
logic [5:0] explosionY;
logic explosion_end;
logic [1:0] explosion_flag;
logic second_explosion; // for super trap


logic [4:0]  crnt_num_ghosts; // Counter for current number of active ghosts (0 to 20)

logic [5:0] hero_X_MSB;
logic [5:0] hero_Y_MSB;
logic [5:0] hero_initial_X_MSB;
logic [5:0] hero_initial_Y_MSB;

assign hero_X_MSB  = hero_X[10:TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze
assign hero_Y_MSB  = hero_Y[10:TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
assign hero_initial_X_MSB  = hero_initial_X[10:TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze
assign hero_initial_Y_MSB  = hero_initial_Y[10:TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze

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

 assign border_address = border_type * 32 * 32 + (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);
 assign ghost_address = (object_flag - 4'hA + explosion_end)* 32 * 32 + (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);
 assign item_address = (object_flag - 4'h2) * 32 * 32 + (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);
 assign grave_address =  grave_appearance * 32 + (offsetY_LSB*TILE_WIDTH_X + offsetX_LSB);


localparam int MAX_num_ghosts = 20;
assign max_num_ghosts = {MAX_num_ghosts[4:0]};

int grave_appearance; // between 0 (not visible) to 32 (visible)
int grave_direction; // +1 or -1 for addition



logic [2:0] CURRENT_STATE;
localparam logic [2:0] OPENING_ST = 3'd0;
localparam logic [2:0] FIRST_LEVEL_ST = 3'd1;
localparam logic [2:0] SECOND_LEVEL_ST = 3'd2;
localparam logic [2:0] VICTORY_ST = 3'd3;
localparam logic [2:0] FAILURE_ST = 3'd4;

assign CURRENT_STATE = GAME_STATE;



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
    {128'h10000000000000030001_000000000000}, // Y = 12
    {128'h10000000000000000001_000000000000}, // Y = 13
    {128'h11111111111111111111_000000000000}, // Y = 14
     // Y = 15: Out of screen bounds (Completely empty padding row)
    {128'h00000000000000000000_000000000000}  
};

logic [0:(MAZE_HEIGHT_Y-1)][0:(MAZE_WIDTH_X-1)] [3:0]   EndOfLevelBitMapMask= // defult table to load on reset
{
     
    {128'h00000000000000000000_000000000000}, // Y = 0
    {128'h00000000000000000000_000000000000}, // Y = 1
    {128'h00000000000000000000_000000000000}, // Y = 2
    {128'h11111111117111111111_000000000000}, // Y = 3
	 {128'h10000000000000000001_000000000000}, // Y = 4 
    {128'h10000000000000000001_000000000000}, // Y = 5
    {128'h10000000000000000001_000000000000}, // Y = 6
    {128'h10000000000000000001_000000000000}, // Y = 7
    {128'h10000000000000000001_000000000000}, // Y = 8
    {128'h10000000000000000001_000000000000}, // Y = 9
    {128'h10000000000000000001_000000000000}, // Y = 10
    {128'h10000000000000000001_000000000000}, // Y = 11
    {128'h10000000000000000001_000000000000}, // Y = 12
    {128'h10000000000000000001_000000000000}, // Y = 13
    {128'h11111111111111111111_000000000000}, // Y = 14
     // Y = 15: Out of screen bounds (Completely empty padding row)
    {128'h00000000000000000000_000000000000}  
};


lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
    .LPM_FILE("RTL/borders.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst (
    .address(border_address),
	 .inclock(clk),
	// .outclock(clk),
    .q(borderColor)
);

 
lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(13),
	 .LPM_NUMWORDS(6144),
    .LPM_FILE("RTL/objects.mif"),
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
    .LPM_WIDTHAD(13),
	 .LPM_NUMWORDS(6144),
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
 
 lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(11),
	 .LPM_NUMWORDS(2048),
    .LPM_FILE("RTL/grave.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst4 (
    .address(grave_address),
	 .inclock(clk),
	// .outclock(clk),
    .q(graveColor)
); 
 

//==----------------------------------------------------------------------------------------------------------------=
always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <=	TRANSPARENT_ENCODING;
		MazeBitMapMask  <=  MazeDefaultBitMapMask ;  //  copy default tabel 
		
		hero_X_MSB_d1 <= hero_initial_X_MSB;
		hero_X_MSB_d2 <= hero_initial_X_MSB - 1'b1;
		hero_Y_MSB_d1 <= hero_initial_Y_MSB;
		hero_Y_MSB_d2 <= hero_initial_Y_MSB;
		direction_d1 <= 4'hB;
		direction_d2 <= 4'hB;
		
		ghosts_history_X <= '{default: 6'h0};
		ghosts_history_Y <= '{default: 6'h0};
		ghosts_history_direction <= '{default: 4'hB};
		
		crnt_num_ghosts <= 5'h0;
		num_ghosts <= 5'd20;
		explosion_end <= 1'b0;
		explosion_flag <= 2'b0;
		generate_trap <= 1'b0;
		second_explosion <= 1'b0;
		
		collision_trap_flag <= 1'b0;
		collision_skull_flag <= 1'b0;
		
		grave_appearance <= 0;
		grave_direction <= 1;
		switch_grave_pos <= 1'b0;
		grave_X <= 6'd0;
		grave_Y <= 6'd0;


	end
	
	else if(CURRENT_STATE == FAILURE_ST) begin 
		RGBout <=	TRANSPARENT_ENCODING;

	end
	
	else if (CURRENT_STATE == OPENING_ST) begin
		
		//do nothing while opening screen
		RGBout <= TRANSPARENT_ENCODING ;

	end
	
	else if (state_transition) begin // not in open or end, only before levels do once
				
		RGBout <=	TRANSPARENT_ENCODING;
		MazeBitMapMask  <=  MazeDefaultBitMapMask ;  //  copy default tabel 
		
		hero_X_MSB_d1 <= hero_initial_X_MSB;
		hero_X_MSB_d2 <= hero_initial_X_MSB - 1'b1;
		hero_Y_MSB_d1 <= hero_initial_Y_MSB;
		hero_Y_MSB_d2 <= hero_initial_Y_MSB;
		direction_d1 <= 4'hB;
		direction_d2 <= 4'hB;
		
		ghosts_history_X <= '{default: 6'h0};
		ghosts_history_Y <= '{default: 6'h0};
		ghosts_history_direction <= '{default: 4'hB};
		
		crnt_num_ghosts <= 5'h0;
		num_ghosts <= 5'd20;
		explosion_end <= 1'b0;
		explosion_flag <= 2'b0;
		generate_trap <= 1'b0;
		second_explosion <= 1'b0;

		collision_trap_flag <= 1'b0;
		collision_skull_flag <= 1'b0;
		
		grave_appearance <= 0;
		grave_direction <= 1;
		switch_grave_pos <= 1'b0;
		grave_X <= 6'd0;
		grave_Y <= 6'd0;
	
	
	end	
	else begin
	
	
		RGBout <= TRANSPARENT_ENCODING ; // default 
		explosion_end <= 1'b0;

		
		
		/////////////////////////////ghosts managing logic///////////////////////////////////
					
		if(((hero_X_MSB != hero_X_MSB_d1) || (hero_Y_MSB != hero_Y_MSB_d1)) && (startOfFrame) && (num_ghosts != 5'd0)) begin	//move ghosts	
		
			if(hero_X_MSB_d1 < hero_X_MSB)
				direction_d1 <= 4'hB;//go right
				
			else if(hero_X_MSB_d1 > hero_X_MSB)
				direction_d1 <= 4'hA;//go left
				
			else if(hero_Y_MSB_d1 < hero_Y_MSB)
				direction_d1 <= 4'hD;//go up
				
			else if(hero_Y_MSB_d1 > hero_Y_MSB)
				direction_d1 <= 4'hC;//go down
	
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
			end 	
			else begin
				crnt_num_ghosts <= crnt_num_ghosts + 5'h1;
			end
			MazeBitMapMask[hero_Y_MSB_d2][hero_X_MSB_d2] <= direction_d2;  //generating new ghost after hero
		
		end
		
		////////////////////////////////// portal at end of level////////////////////
		
		if(open_sesame && startOfFrame) begin
			MazeBitMapMask  <=  EndOfLevelBitMapMask ;  //  copy end tabel 
			num_ghosts <= 5'd0;
			generate_trap <= 1'b0;
			generate_pwr_item <= 1'b0;


		end
		
		/////////////////////////////// graves of fury //////////////////////////////
		if (CURRENT_STATE == SECOND_LEVEL_ST && motion_pulse) begin
		
			if (grave_appearance <= 0) begin // grave in ground
				switch_grave_pos <= 1'b1;
				grave_direction <= 1;
				MazeBitMapMask[grave_Y][grave_X] <= 4'd0;  //delete grave

			end

			else if (grave_appearance >= 32) begin
				grave_direction <= -1;
				
			end
			else if (check_random_valid && switch_grave_pos && explosion_flag == 2'd0) begin //place to put grave, one clk after start of frame so acceptable
				grave_X <= random_X_MSB;// saving grave for delete
				grave_Y <= random_Y_MSB;
				MazeBitMapMask[random_Y_MSB][random_X_MSB] <= 4'd9;  //put pwr item
				switch_grave_pos <= 1'b0;
				
			end
			else begin
				grave_appearance <= grave_appearance + grave_direction; // cycling grave appearence
			
			end
			
		end
		
		////////////////////////////////// collision hero trap //////////////////////
		
		//-------exploding ghost---------------
		if(object_flag == 4'hE && explosion_flag == 2'd3)
			explosion_end <= 1'd1;//for stepping up the adress to next mif

		else if (motion_pulse && explosion_flag > 2'd0 && explosion_flag < 2'd3) //explostion phaze 2
			explosion_flag <= explosion_flag + 2'd1;//counter++
		
		else if (motion_pulse && explosion_flag == 2'd3) begin
			MazeBitMapMask[explosionY][explosionX] <= 4'h0;  //deleting last ghost when explosion ends
			explosion_flag <= 2'd0;
		end	
		//-------------------------------------
		
		else if (collision_hero_trap) begin
			collision_trap_flag <= 1'b1;
			hit_X <= offsetX_MSB;//save coordinates for deleting the trap next startOfFrame
			hit_Y <= offsetY_MSB;
		end
		else if (collision_trap_flag && startOfFrame) begin
			MazeBitMapMask[hit_Y][hit_X] <= 4'h0;  // deleting trap 
			collision_trap_flag <= 1'b0;
			generate_trap <= 1'b1;
			
			MazeBitMapMask[ghosts_history_Y[crnt_num_ghosts-1]][ghosts_history_X[crnt_num_ghosts-1]] <= 4'hE;  //exploding last ghost when stepping on trap
			explosion_flag <= 2'd1; // starting exploding ghost drill
			
			explosionX <= ghosts_history_X[crnt_num_ghosts-1];//saving pos for deleting ghost
			explosionY <= ghosts_history_Y[crnt_num_ghosts-1];

			crnt_num_ghosts <= crnt_num_ghosts - 1'b1;
			num_ghosts <= num_ghosts - 1'b1;
		end

		else if (check_random_valid && generate_trap && explosion_flag == 2'd0) begin //place to put trap, one clk after start of frame so acceptable, makimg sure not to generate trap until explosion ends
			MazeBitMapMask[random_Y_MSB][random_X_MSB] <= 4'h2;  //put trap
			generate_trap <= 1'b0;
		end
		
		////////////////////////////////// collision hero skull //////////////////////
		
		else if (collision_hero_skull) begin
			hit_X <= offsetX_MSB;//save coordinates for deleting the item next startOfFrame
			hit_Y <= offsetY_MSB;	
			collision_skull_flag <= 1'b1;
		end
		
		else if (collision_skull_flag && startOfFrame) begin
			MazeBitMapMask[hit_Y][hit_X] <= 4'h0;  // deleting item 
			collision_skull_flag <= 1'b0;
			generate_pwr_item <= 1'b1;
				
			if (num_ghosts < MAX_num_ghosts)
				num_ghosts <= num_ghosts + 1'b1; // skull pwr - adding ghost
		end
		
		////////////////////////////////// collision hero inverse keys or slow time //////////////////////
		
		else if (collision_hero_inverse_keys_pd || collision_hero_slow_time_pu) begin
			hit_X <= offsetX_MSB;//save coordinates for deleting the item next startOfFrame
			hit_Y <= offsetY_MSB;	
			collision_passive_item_flag <= 1'b1;
		end
			
		else if (collision_passive_item_flag && startOfFrame) begin
			MazeBitMapMask[hit_Y][hit_X] <= 4'h0;  // deleting item 
			collision_passive_item_flag <= 1'b0;
			generate_pwr_item <= 1'b1;
				
		end
		////////////////////////////////// collision hero super trap//////////////////////

		else if (collision_hero_super_trap_pu) begin
			hit_X <= offsetX_MSB;//save coordinates for deleting the item next startOfFrame
			hit_Y <= offsetY_MSB;	
			collision_super_trap_flag <= 1'b1;
		end
			
		else if (collision_super_trap_flag && explosion_flag == 2'd0 && startOfFrame) begin
			MazeBitMapMask[hit_Y][hit_X] <= 4'h0;  // deleting item 
			collision_super_trap_flag <= 1'b0;
			
			second_explosion <= 1'b1;//trigger to set off second explosion
			MazeBitMapMask[ghosts_history_Y[crnt_num_ghosts-1]][ghosts_history_X[crnt_num_ghosts-1]] <= 4'hE;  //exploding last ghost when stepping on trap
			explosion_flag <= 2'd1; // starting exploding ghost drill
			
			explosionX <= ghosts_history_X[crnt_num_ghosts-1];//saving pos for deleting ghost
			explosionY <= ghosts_history_Y[crnt_num_ghosts-1];

			crnt_num_ghosts <= crnt_num_ghosts - 1'b1;
			num_ghosts <= num_ghosts - 1'b1;
		end
		
		else if (second_explosion && explosion_flag == 2'd0 && motion_pulse) begin//second explosion !!!!!!!!!!!!bug fix unchecked !!!!!!!!!!!!!!!!!!!!!!!!
			generate_pwr_item <= 1'b1;
			second_explosion <= 1'b0;//turn off trigger
			
			MazeBitMapMask[ghosts_history_Y[crnt_num_ghosts-1]][ghosts_history_X[crnt_num_ghosts-1]] <= 4'hE;  //exploding last ghost when stepping on trap
			explosion_flag <= 2'd1; // starting exploding ghost drill
			
			explosionX <= ghosts_history_X[crnt_num_ghosts-1];//saving pos for deleting ghost
			explosionY <= ghosts_history_Y[crnt_num_ghosts-1];

			crnt_num_ghosts <= crnt_num_ghosts - 1'b1;
			num_ghosts <= num_ghosts - 1'b1;
		end
		
		
		///////////////////////////////// generating random pwr item /////////////////////
		
		else if (check_random_valid && generate_pwr_item && explosion_flag == 2'd0) begin //place to put pwr item, one clk after start of frame so acceptable
				MazeBitMapMask[random_Y_MSB][random_X_MSB] <= random_item;  //put pwr item
				generate_pwr_item <= 1'b0;
		end
		
		///////////////////////////////////crnt object color out////////////////////////////////////////
		
		if (InsideRectangle == 1'b1 )	begin 
		   	case (object_flag)
					 4'h0 : RGBout <= TRANSPARENT_ENCODING ;
			   	 4'h1 : RGBout <= borderColor; 
					 
					 4'h2 : RGBout <= itemColor ; 
					 4'h3 : RGBout <= itemColor ;
					 4'h4 : RGBout <= itemColor ; 
					 4'h5 : RGBout <= itemColor ; 
					 4'h6 : RGBout <= itemColor ; 
					 4'h7 : RGBout <= itemColor ;
//					 4'h8 : RGBout <= itemColor ; 

					 4'h9 : RGBout <= graveColor ; 
					 
					 4'hA : RGBout <= ghostColor;
					 4'hB : RGBout <= ghostColor;
					 4'hC : RGBout <= ghostColor;
					 4'hD : RGBout <= ghostColor;
					 4'hE : RGBout <= ghostColor;


					 default:  RGBout <= TRANSPARENT_ENCODING ; 
				endcase
		end 

	end 
end

//==----------------------------------------------------------------------------------------------------------------=
// decide if to draw the pixel or not 
assign drawingRequest[0] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h1)) ? 1'b1 : 1'b0 ; // borderDrawingRequest 
assign drawingRequest[1] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h2)) ? 1'b1 : 1'b0 ; // trapDrawingRequest

assign drawingRequest[2] = ((RGBout != TRANSPARENT_ENCODING) && ((object_flag == 4'hA) || (object_flag == 4'hB) || 
																					  (object_flag == 4'hC) || (object_flag == 4'hD) || 
																					  (object_flag == 4'hE))) ? 1'b1 : 1'b0 ; // ghostFrawingRequest
																					  
assign drawingRequest[3] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h3)) ? 1'b1 : 1'b0 ; // skullDrawingRequest

assign drawingRequest[4] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h7)) ? 1'b1 : 1'b0 ; // portalDrawingRequest
assign drawingRequest[5] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h9)) ? 1'b1 : 1'b0 ; // graveDrawingRequest
assign drawingRequest[6] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h4)) ? 1'b1 : 1'b0 ; // inverse_keys_pd_DrawingRequest
assign drawingRequest[7] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h5)) ? 1'b1 : 1'b0 ; // slow_time_pu_DrawingRequest
assign drawingRequest[8] = ((RGBout != TRANSPARENT_ENCODING) && (object_flag == 4'h6)) ? 1'b1 : 1'b0 ; // super_trap_pu_DrawingRequest



assign random_X_MSB  = RandomPixelX[10:TILE_NUMBER_OF_X_BITS] ; // get offset of tile in maze
assign random_Y_MSB  = RandomPixelY[10:TILE_NUMBER_OF_Y_BITS] ; // get higher bits 
 																		  

assign in_borders = (0 < random_X_MSB) && (4 < random_Y_MSB) && (random_Y_MSB < 15) && (random_X_MSB < 20);//between borders

assign unoccupied = ((MazeBitMapMask[random_Y_MSB][random_X_MSB] == 4'h0) && (random_X_MSB != hero_X_MSB_d1) && (random_Y_MSB != hero_Y_MSB_d1)
																								  && (random_X_MSB != hero_X_MSB_d2) && (random_Y_MSB != hero_Y_MSB_d2));

assign check_random_valid = in_borders && unoccupied;


always_comb begin
	case (CURRENT_STATE)
			FIRST_LEVEL_ST : begin
				border_type = 2'd0;
				
			end
			
			SECOND_LEVEL_ST : begin
				border_type = 2'd1;

			end
			
			default : begin
				border_type = 2'd0;

			end	
		endcase
end


endmodule

