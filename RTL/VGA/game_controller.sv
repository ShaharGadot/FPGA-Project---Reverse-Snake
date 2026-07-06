


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
			
			input	logic [3:0] big_min_count,
			input	logic [3:0] small_min_count,
			input	logic [3:0] big_sec_count,
			input	logic [3:0] small_sec_count,

			
			output logic collision_hero_trap, // collisions are active in case of collision between objects
			output logic collision_hero_skull,
			output logic collision_hero_inverse_keys_pd,
			output logic collision_hero_slow_time_pu,
			output logic collision_hero_super_trap_pu,
			
			output logic [2:0] GAME_STATE,
			output logic state_transition,
			
			output logic open_sesame,
			
			output logic [3:0] inverse_countdown,
			output logic [3:0] slow_time_countdown,
			
			output logic [3:0] big_min_HS,
			output logic [3:0] small_min_HS,
			output logic [3:0] big_sec_HS ,
			output logic [3:0] small_sec_HS

			
);




logic portal_flag;
logic SinglePulse_PortalCollision;

logic state_transition_margin;

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

logic [15:0] points_HS;
logic [15:0] points_crnt;

logic [3:0] big_min_HS_reg   = 4'd5; // initial reset
logic [3:0] small_min_HS_reg = 4'd9;
logic [3:0] big_sec_HS_reg   = 4'd5;
logic [3:0] small_sec_HS_reg = 4'd9;

assign big_min_HS   = big_min_HS_reg; // not changing directly the output
assign small_min_HS = small_min_HS_reg;
assign big_sec_HS   = big_sec_HS_reg;
assign small_sec_HS = small_sec_HS_reg;

assign points_HS = big_min_HS_reg * 1000 + small_min_HS_reg * 100 + big_sec_HS_reg * 10 + small_sec_HS_reg;
assign points_crnt = big_min_count * 1000 + small_min_count * 100 + big_sec_count * 10 + small_sec_count; // to compare crnt and high score



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

logic collision_hero_border;
logic collision_hero_ghost;
logic collision_hero_portal;
logic collision_hero_grave;

	
assign collision_hero_trap = (TrapDrawingRequest && HeroDrawingRequest); //
assign collision_hero_border = (BorderDrawingRequest && HeroDrawingRequest);
assign collision_hero_ghost = (GhostDrawingRequest && HeroDrawingRequest);
assign collision_hero_skull = (SkullDrawingRequest && HeroDrawingRequest); //

assign collision_hero_portal = (portalDrawingRequest && HeroDrawingRequest);
assign collision_hero_grave = (graveDrawingRequest && HeroDrawingRequest);
assign collision_hero_inverse_keys_pd = (inverse_keys_pd_DrawingRequest && HeroDrawingRequest); //
assign collision_hero_slow_time_pu = (slow_time_pu_DrawingRequest && HeroDrawingRequest); //
assign collision_hero_super_trap_pu = (super_trap_pu_DrawingRequest && HeroDrawingRequest); //

// ---------------------------------------------------------------------------

logic [2:0] SM_GAME_q;

enum  logic [2:0] {  OPENING_ST,
							FIRST_LEVEL_ST,
							SECOND_LEVEL_ST,
							VICTORY_ST,
							FAILURE_ST
						}  SM_GAME ;



always_ff@(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if(!resetN)
	begin 
		SM_GAME <= OPENING_ST ; 
		open_sesame <= 1'b0;

	end 
	else begin 
		open_sesame <= 1'b0;

	
			case (SM_GAME) 
			
			//-----------------
				OPENING_ST : begin
			//-----------------
					if (enter) begin
						SM_GAME <= FIRST_LEVEL_ST;

					end
				end
				
			//-----------------
				FIRST_LEVEL_ST : begin
			//-----------------
					
					if (num_ghosts == 5'd0 || minus) // finished ghosts or CHEAT
						open_sesame <= 1'b1;
					
					
					
					if ((collision_hero_border || collision_hero_ghost || collision_hero_grave) && (!state_transition_margin)) begin
						SM_GAME <= FAILURE_ST; //4

					end

						
					else if (SinglePulse_PortalCollision && (!state_transition_margin)) begin // make sure the collision ends after clk
						SM_GAME <= SECOND_LEVEL_ST; //2

					end

				end
				
				//-----------------
				SECOND_LEVEL_ST : begin
			//-----------------					
					
					if (num_ghosts == 5'd0 || minus) // finished ghosts or CHEAT
						open_sesame <= 1'b1;
					
					if ((collision_hero_border || collision_hero_ghost || collision_hero_grave) && (!state_transition_margin)) begin
						SM_GAME <= FAILURE_ST; //4

					end
					
					else if (SinglePulse_PortalCollision && (!state_transition_margin)) begin // make sure the collision ends after clk
						SM_GAME <= VICTORY_ST; //3

					end

				end
				
			//-----------------
				VICTORY_ST : begin
			//-----------------

					
					
					if (enter) begin
						SM_GAME <= FIRST_LEVEL_ST;

					end
					
				end
				
				//-----------------
				FAILURE_ST : begin
			//-----------------
			
					if (enter) begin
						SM_GAME <= FIRST_LEVEL_ST;
						
					end
					
				end
			
			endcase
 
	end 
end


always_comb begin
    case (SM_GAME)
	 
        OPENING_ST : GAME_STATE = 3'd0;
        FIRST_LEVEL_ST : GAME_STATE = 3'd1;
        SECOND_LEVEL_ST : GAME_STATE = 3'd2;
        VICTORY_ST : GAME_STATE = 3'd3;
        FAILURE_ST : GAME_STATE = 3'd4;
		  
        default : GAME_STATE = 3'd0;
		  
    endcase
end

////////////////////////// for game transition ///////////////////////

always_ff @(posedge clk or negedge resetN) begin 
    if (!resetN) begin
        SM_GAME_q <= OPENING_ST;
        state_transition <= 1'b0;
		  state_transition_margin <= 1'b0;

    end else begin
        SM_GAME_q <= SM_GAME; 
        
        if (SM_GAME != SM_GAME_q) begin
            state_transition <= 1'b1;	
				state_transition_margin <= 1'b1;
				
        end 
		  else begin
            state_transition <= 1'b0;
				
				if (one_sec_pulse) 
					state_transition_margin <= 1'b0; // one sec (tops) margin after state transition
				
        end
		  
    end
end

/////////////////////////////countdowns////////////////////////////////////

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		inverse_countdown_activated <= 1'b0;
		inverse_countdown <= 4'd0;
		
		slow_time_countdown_activated <= 1'b0;
		slow_time_countdown <= 4'd0;
	end
	
	else begin
	
		if (state_transition == 1'b1) begin // cancle pwr ups between levels
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
		
			if (inverse_countdown == 4'd0)
				inverse_countdown_activated <= 1'b0;
			else
				inverse_countdown <= inverse_countdown - 1'b1;	
			
		end
		
		/////////////////////////////////////////// slow time coundown when activated /////////////

		else if (collision_hero_slow_time_pu) begin
				slow_time_countdown_activated <= 1'b1;
				slow_time_countdown <= 4'd5;
		end
			
		else if (slow_time_countdown_activated && one_sec_pulse) begin
		
			if (slow_time_countdown == 4'd0)
				slow_time_countdown_activated <= 1'b0;
			else
				slow_time_countdown <= slow_time_countdown - 1'b1;	
			
		end
		
			
	end
end	

//////////////////////////////////////// saving new high score (without reseting) ///////////////////////////////

//initial begin
//    big_min_HS   = 4'd5;
//    small_min_HS = 4'd9;
//    big_sec_HS   = 4'd5;
//    small_sec_HS = 4'd9;
//end

always_ff@(posedge clk)
begin

	if (SM_GAME == VICTORY_ST) begin
	
		if (points_crnt < points_HS) begin // save high score
		
			big_min_HS_reg   <= big_min_count;
         small_min_HS_reg <= small_min_count;
         big_sec_HS_reg   <= big_sec_count;
         small_sec_HS_reg <= small_sec_count;
		end
	end
end



////////////////////////////////////////////// cooldown for portal collision /////////////////////////////

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin 
		portal_flag	<= 1'b0;
		SinglePulse_PortalCollision <= 1'b0 ; 
		
	end 
	else begin 
	
			SinglePulse_PortalCollision <= 1'b0 ; // default 
			if(one_sec_pulse) 
				portal_flag <= 1'b0 ; // reset for next time 
				

if ( collision_hero_portal && (portal_flag == 1'b0)) begin 
			portal_flag	<= 1'b1; // to enter only once 
			SinglePulse_PortalCollision <= 1'b1 ; 
		end ; 
 
	end 
end

endmodule

