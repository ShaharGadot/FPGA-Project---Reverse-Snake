// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal MAR 2024   
// good practice code - Dudy MAR 2025  ert

module	hero_move	(	
 
					input	 logic clk,
					input	 logic resetN,
					input	 logic startOfFrame,      //short pulse every start of frame 30Hz 
					input	 logic up_key,      //8 for up 
					input	 logic down_key,      //2 for down 
					input	 logic right_key,      //6 for right
					input	 logic left_key,      //4 for left
					input  logic [2:0] GAME_STATE,
					input	 logic state_transition,
					input  logic [3:0] inverse_countdown,
					input  logic [3:0] slow_time_countdown,

					
					output logic [10:0] initial_X, // output the top left corner 
					output logic [10:0] initial_Y, // output the top left corner 

					output logic signed 	[10:0] topLeftX, // output the top left corner 
					output logic signed	[10:0] topLeftY,  // can be negative , if the object is partliy outside 
					output logic [3:0] digit // which direction the character is moving
					
);

logic UP;
logic DOWN;
logic RIGHT;
logic LEFT;
		
logic slow_time_flag;
		
 int 	 topLeftX_tmp; // output the top left corner 
 int   topLeftY_tmp;  // can be negative , if the object is partliy outside 

// a module used to generate the  ball trajectory.  

parameter int INITIAL_X = 256;
parameter int INITIAL_Y = 160;
parameter int player_speed = 128;

int crnt_speed;

//const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
const logic signed 	[10:0]	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


// movement limits 
const int   OBJECT_WIDTH_X = 32;
const int   OBJECT_HIGHT_Y = 32;
const int	SafetyMargin   =	2;

const int	x_FRAME_LEFT	=	(SafetyMargin)* FIXED_POINT_MULTIPLIER; 
const int	x_FRAME_RIGHT	=	(639 - SafetyMargin - OBJECT_WIDTH_X)* FIXED_POINT_MULTIPLIER; 
const int	y_FRAME_TOP		=	(SafetyMargin) * FIXED_POINT_MULTIPLIER;
const int	y_FRAME_BOTTOM	=	(479 -SafetyMargin - OBJECT_HIGHT_Y ) * FIXED_POINT_MULTIPLIER; //- OBJECT_HIGHT_Y


typedef enum logic [2:0] {
	 OPENING_ST     = 3'd0,
    FIRST_LEVEL_ST = 3'd1,
	 SECOND_LEVEL_ST = 3'd2,
    FAILURE_ST     = 3'd3
} local_state;

local_state CURRENT_STATE;

assign CURRENT_STATE = local_state'(GAME_STATE);


always_comb begin

///////////////////////////// inverse keys pwr //////////////////////////////////

	if (inverse_countdown != 4'd0) begin // inverse activated
		UP = down_key;
		DOWN = up_key;
		RIGHT	= left_key;
		LEFT = right_key;
	end
	else begin // normal settings
		UP = up_key;
		DOWN = down_key;
		RIGHT	= right_key;
		LEFT = left_key;
	end
	
///////////////////////////// slow time keys pwr //////////////////////////////////

	if (slow_time_countdown != 4'd0) // slow time activated
		crnt_speed = player_speed / 2;
	
	else
		crnt_speed = player_speed;
		
end


 ////////////////////////////////////////////////////////////////////////////////////

typedef struct packed {
 	 int Y_speed;
 	 int X_speed;
	 logic [3:0] dig;
 } change_direction_req;

change_direction_req req;
 
logic X_in_grid;
logic Y_in_grid;
logic change_direction_flag;



enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST  // check if inside the frame  
						}  SM_Motion ;

int Xspeed  ; // speed    
int Yspeed  ; 
int Xposition ; //position   
int Yposition ;  

 //---------
 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (!resetN) begin 
		SM_Motion <= IDLE_ST ; 
		Xspeed <= 0   ; 
		Yspeed <= 0  ; 
		digit <= 4'd4; // player starts to the right
		Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER  ; 
		Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER   ; 
		change_direction_flag <= 1'b0;
		slow_time_flag <= 1'b0;

	
	end 	
	
	else if (CURRENT_STATE == FAILURE_ST) begin 
		// wait untill start of a level

	end 
	
	else if (CURRENT_STATE == OPENING_ST) begin
		// wait untill start of a level
	end
	
		else if (state_transition) begin // not in open or end, only before levels do once
			SM_Motion <= IDLE_ST ; 
			Xspeed <= 0   ; 
			Yspeed <= 0  ; 
			digit <= 4'd4; // player starts to the right
			Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER  ; 
			Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER   ; 
			change_direction_flag <= 1'b0;
			slow_time_flag <= 1'b0;

				

//		case (CURRENT_STATE)
//			FIRST_LEVEL_ST : begin
//				
//			end
//			
//			SECOND_LEVEL_ST : begin
//
//			end
//			
//			default : begin
//
//			end	
//		endcase
	
	end	
	
	else begin
	
	
		case(SM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
		
				Xspeed  <= crnt_speed ; // player starts to the left
				Yspeed  <= 0  ; 
				Xposition <= INITIAL_X*FIXED_POINT_MULTIPLIER; 
				Yposition <= INITIAL_Y*FIXED_POINT_MULTIPLIER; 

				if (startOfFrame) 
					SM_Motion <= MOVE_ST ;
 	
			end
	
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
		//------------
		// keys direction change 
		
			if(!change_direction_flag) begin
				if (UP && Yspeed <= 0 ) begin
					req.Y_speed <= -crnt_speed; 
					req.X_speed <= 0; 
					req.dig <= 4'd2; // back
					change_direction_flag <= 1'b1;

				end
					
				else if (DOWN && Yspeed >= 0 ) begin
					req.Y_speed <= crnt_speed; 
					req.X_speed <= 0; 
					req.dig <= 4'd0; // front
					change_direction_flag <= 1'b1;

				end
				
				else if (RIGHT && Xspeed >= 0 ) begin
					req.Y_speed <= 0; 
					req.X_speed <= crnt_speed;
					req.dig <= 4'd4; // right
					change_direction_flag <= 1'b1;

				end
		
				else if (LEFT && Xspeed <= 0 ) begin
					req.Y_speed <= 0; 
					req.X_speed <= -crnt_speed; 
					req.dig <= 4'd6; // left
					change_direction_flag <= 1'b1;

				end
				
			end 
				else if (change_direction_flag && X_in_grid && Y_in_grid) begin
				
					Yspeed <= req.Y_speed; 
					Xspeed <= req.X_speed; 
					digit <= req.dig;
					
					if (startOfFrame )
						change_direction_flag <= 1'b0;
				end

				if (startOfFrame )
					SM_Motion <= POSITION_CHANGE_ST ; 
					
					
				
		end 
		

		//------------------------
			POSITION_CHANGE_ST : begin  // position interpolate 
		//------------------------
	
				Xposition <= Xposition + Xspeed ; 
				Yposition <= Yposition + Yspeed ;
			 
				// accelerate 
		
	
				
				SM_Motion <= POSITION_LIMITS_ST ; 
			end
		
		//------------------------
			POSITION_LIMITS_ST : begin  //check if still inside the frame 
		//------------------------
		if (Xposition < x_FRAME_LEFT) 
						Xposition <= x_FRAME_LEFT ; 
		if (Xposition > x_FRAME_RIGHT)
						Xposition <= x_FRAME_RIGHT ; 
		if (Yposition < y_FRAME_TOP) 
						Yposition <= y_FRAME_TOP ; 
		if (Yposition > y_FRAME_BOTTOM) 
						Yposition <= y_FRAME_BOTTOM ; 

				SM_Motion <= MOVE_ST ; 
			
			end
		
		endcase  // case 

		
	end 

end // end fsm_sync


//return from FIXED point trunc back to prame size parameters 
  
assign 	topLeftX_tmp = Xposition / FIXED_POINT_MULTIPLIER ;   // note it must be 2^n 
assign 	topLeftY_tmp = Yposition / FIXED_POINT_MULTIPLIER ;    

assign 	topLeftX = {topLeftX_tmp[10:0]} ;   // note it must be 2^n 
assign 	topLeftY = {topLeftY_tmp[10:0]} ; 

assign 	initial_X = {INITIAL_X[10:0]} ;   // note it must be 2^n 
assign 	initial_Y = {INITIAL_Y[10:0]} ; 
   	

assign X_in_grid = topLeftX[4:0] == 5'b0; 

assign Y_in_grid = topLeftY[4:0] == 5'b0; 

endmodule	
//---------------
 
