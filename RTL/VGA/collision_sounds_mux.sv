

module	collision_sounds_mux	(	
		 

					
			input logic collision_hero_trap, 
			input logic collision_hero_skull,
			input logic collision_hero_inverse_keys_pd,
			input logic collision_hero_slow_time_pu,
			input logic collision_hero_super_trap_pu,
			
			input logic [2:0] GAME_STATE,
			input logic state_transition,
			
			
			output logic enable_sound,
			output logic [3:0] tune,
			output logic stopMelody
);


logic stop_melody;

logic [2:0] CURRENT_STATE;
localparam logic [2:0] OPENING_ST = 3'd0;
localparam logic [2:0] FIRST_LEVEL_ST = 3'd1;
localparam logic [2:0] SECOND_LEVEL_ST = 3'd2;
localparam logic [2:0] THIRD_LEVEL_ST = 3'd3;
localparam logic [2:0] VICTORY_ST = 3'd4;
localparam logic [2:0] FAILURE_ST = 3'd5;

assign CURRENT_STATE = GAME_STATE;
assign stopMelody = stop_melody;

always_comb begin

	enable_sound = 1'b0;
   tune = 4'd0;
	stop_melody <= 1'b0;


	
	if (collision_hero_trap) begin
	
		enable_sound = 1'b1;
		tune = 4'd0;
		
	end
	else if (CURRENT_STATE == FAILURE_ST && state_transition) begin
	
		enable_sound = 1'b1;
		tune = 4'd1;
		
		
	end
	else if (CURRENT_STATE == FIRST_LEVEL_ST && state_transition) begin // stoping opening music
	
		stop_melody <= 1'b1;
		
		
	end
	else if (collision_hero_skull) begin
	
		enable_sound = 1'b1;
		tune = 4'd2;
		
		
	end
	else if (collision_hero_slow_time_pu || collision_hero_inverse_keys_pd || collision_hero_super_trap_pu) begin
	
		enable_sound = 1'b1;
		tune = 4'd3;
		
		
	end
	
	else if (CURRENT_STATE == VICTORY_ST && state_transition) begin
	
		enable_sound = 1'b1;
		tune = 4'd4;
		
		
	end
	
	else if (CURRENT_STATE == OPENING_ST && state_transition) begin
	
		enable_sound = 1'b1;
		tune = 4'd5;
		
		
	end


end

endmodule


