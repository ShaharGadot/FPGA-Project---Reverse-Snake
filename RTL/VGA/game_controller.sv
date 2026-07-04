


module	game_controller	(	
			input	logic	clk,
			input	logic	resetN,
			input	logic	startOfFrame,  // short pulse every start of frame 30Hz
			input logic enter,
			input logic minus,
			input logic [4:0] num_ghosts,
		
		
			input	logic	[8:0] GridDrawingRequest,	
			input	logic	HeroDrawingRequest,
			
			input logic one_sec_pulse,

			
			output logic collision_hero_trap, // collisions are active in case of collision between objects
			output logic collision_hero_skull,
			output logic collision_hero_inverse_keys_pd,
			output logic collision_hero_slow_time_pu,
			output logic collision_hero_super_trap_pu,
			
			output logic [2:0] GAME_STATE,
			output logic state_transition,
			
			output logic open_sesame,
			
			output logic [3:0] inverse_countdown,
			output logic [3:0] slow_time_countdown


			//output logic SinglePulse_TrapCollision //generating A single pulse in a frame in trap collision 
			
);

//logic flag ; // a semaphore to set the output only once per frame regardless of number of collisions 


logic BorderDrawingRequest;
logic TrapDrawingRequest;
logic GhostDrawingRequest;
logic SkullDrawingRequest;

logic portalDrawingRequest;
logic graveDrawingRequest;
logic inverse_keys_pd_DrawingRequest;
logic slow_time_pu_DrawingRequest;
logic super_trap_pu_DrawingRequest;

logic inverse_countdown_activated;
logic slow_time_countdown_activated;


assign BorderDrawingRequest = GridDrawingRequest[0];
assign TrapDrawingRequest = GridDrawingRequest[1];
assign GhostDrawingRequest = GridDrawingRequest[2];
assign SkullDrawingRequest = GridDrawingRequest[3];

assign portalDrawingRequest = GridDrawingRequest[4];
assign graveDrawingRequest = GridDrawingRequest[5];
assign inverse_keys_pd_DrawingRequest = GridDrawingRequest[6];
assign slow_time_pu_DrawingRequest = GridDrawingRequest[7];
assign super_trap_pu_DrawingRequest = GridDrawingRequest[8];

						
// -----------------------collisions----------------------------------------		
assign collision_hero_trap = (TrapDrawingRequest && HeroDrawingRequest); //
assign collision_hero_border = (BorderDrawingRequest && HeroDrawingRequest);
assign collision_hero_ghost = (GhostDrawingRequest && HeroDrawingRequest);
assign collision_hero_skull = (SkullDrawingRequest && HeroDrawingRequest); //

assign collision_hero_portal = (portalDrawingRequest && HeroDrawingRequest);
assign collision_hero_grave = (graveDrawingRequest && graveDrawingRequest);
assign collision_hero_inverse_keys_pd = (inverse_keys_pd_DrawingRequest && HeroDrawingRequest); //
assign collision_hero_slow_time_pu = (slow_time_pu_DrawingRequest && HeroDrawingRequest); //
assign collision_hero_super_trap_pu = (super_trap_pu_DrawingRequest && HeroDrawingRequest); //

// ---------------------------------------------------------------------------

enum  logic [2:0] {  OPENING_ST,
							FIRST_LEVEL_ST,
							SECOND_LEVEL_ST,
							FAILURE_ST
						}  SM_GAME ;




always_ff@(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if(!resetN)
	begin 
		SM_GAME <= OPENING_ST ; 
		GAME_STATE <= 3'd0;
		state_transition <= 1'b0;
		open_sesame <= 1'b0;

	end 
	else begin 
		state_transition <= 1'b0;
		open_sesame <= 1'b0;

	
			case (SM_GAME) 
			
			//-----------------
				OPENING_ST : begin
			//-----------------
					GAME_STATE <= 3'd0;
					if (enter) begin
						SM_GAME <= FIRST_LEVEL_ST;
						state_transition <= 1'b1;
					end
				end
				
			//-----------------
				FIRST_LEVEL_ST : begin
			//-----------------
					GAME_STATE <= 3'd1;
					
					if (num_ghosts == 5'd0 || minus) // finished ghosts or CHEAT
						open_sesame <= 1'b1;
					
					
					
					if (collision_hero_border || collision_hero_ghost) begin
						SM_GAME <= FAILURE_ST;
						state_transition <= 1'b1;
					end

						
					else if (collision_hero_portal) begin
						SM_GAME <= SECOND_LEVEL_ST;
						state_transition <= 1'b1;
					end

				end
				
				//-----------------
				SECOND_LEVEL_ST : begin
			//-----------------
					GAME_STATE <= 3'd2;
					
					
					
					if (collision_hero_border || collision_hero_ghost) begin
						SM_GAME <= FAILURE_ST;
						state_transition <= 1'b1;
					end

				end
				
			//-----------------
				FAILURE_ST : begin
			//-----------------
			
					GAME_STATE <= 3'd3;
					if (enter) begin
						SM_GAME <= FIRST_LEVEL_ST;
						state_transition <= 1'b1;
					end
					
				end
			
			endcase
 
	end 
end






always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		inverse_countdown_activated <= 1'b0;
		inverse_countdown <= 4'd0;
		
		slow_time_countdown_activated <= 1'b0;
		slow_time_countdown <= 4'd0;
	end
	
	else begin
	
		if (state_transition <= 1'b1) begin // cancle pwr ups between levels
			inverse_countdown_activated <= 1'b0;
			inverse_countdown <= 4'd0;
			
			slow_time_countdown_activated <= 1'b0;
			slow_time_countdown <= 4'd0;
		end

		/////////////////////////////////////////// inverse coundown when activated /////////////

		else if (collision_hero_inverse_keys_pd) begin
				inverse_countdown_activated <= 1'b1;
				inverse_countdown <= 4'd10;
		end
			
		else if (inverse_countdown_activated && one_sec_pulse) begin
		
			if (inverse_countdown == 4'd1)
				inverse_countdown_activated <= 1'b0;
			else
				inverse_countdown <= inverse_countdown - 1'b1;	
			
		end
		
		/////////////////////////////////////////// slow time coundown when activated /////////////

		else if (collision_hero_slow_time_pu) begin
				slow_time_countdown_activated <= 1'b1;
				slow_time_countdown <= 4'd10;
		end
			
		else if (slow_time_countdown_activated && one_sec_pulse) begin
		
			if (slow_time_countdown == 4'd1)
				slow_time_countdown_activated <= 1'b0;
			else
				slow_time_countdown <= slow_time_countdown - 1'b1;	
			
		end
		
			
	end
end	



















//always_ff@(posedge clk or negedge resetN)
//begin
//	if(!resetN)
//	begin 
//		flag	<= 1'b0;
//		SinglePulse_TrapCollision <= 1'b0 ; 
//		
//	end 
//	else begin 
//	
//			SinglePulse_TrapCollision <= 1'b0 ; // default 
//			if(startOfFrame) 
//				flag <= 1'b0 ; // reset for next time 
//				
//
//if ( collision_hero_trap && (flag == 1'b0)) begin 
//			flag	<= 1'b1; // to enter only once 
//			SinglePulse_TrapCollision <= 1'b1 ; 
//		end ; 
// 
//	end 
//end

endmodule

