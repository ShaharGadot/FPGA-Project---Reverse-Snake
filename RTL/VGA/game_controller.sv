


module	game_controller	(	
			input	logic	clk,
			input	logic	resetN,
			input	logic	startOfFrame,  // short pulse every start of frame 30Hz
		
		
			input	logic	[3:0] GridDrawingRequest,	
			input	logic	HeroDrawingRequest,

			
			output logic collision_hero_trap, // collisions are active in case of collision between objects
			output logic collision_hero_border,
			output logic collision_hero_skull,


			output logic SinglePulse_TrapCollision //generating A single pulse in a frame in trap collision 
			
);

logic BorderDrawingRequest;
logic TrapDrawingRequest;
logic GhostDrawingRequest;
logic SkullDrawingRequest;

assign BorderDrawingRequest = GridDrawingRequest[0];
assign TrapDrawingRequest = GridDrawingRequest[1];
assign GhostDrawingRequest = GridDrawingRequest[2];
assign SkullDrawingRequest = GridDrawingRequest[3];




logic flag ; // a semaphore to set the output only once per frame regardless of number of collisions 


assign collision_hero_trap = (TrapDrawingRequest && HeroDrawingRequest);
assign collision_hero_border = (BorderDrawingRequest && HeroDrawingRequest);
assign collision_hero_ghost = (GhostDrawingRequest && HeroDrawingRequest);
assign collision_hero_skull = (SkullDrawingRequest && HeroDrawingRequest);



always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN)
	begin 
		flag	<= 1'b0;
		SinglePulse_TrapCollision <= 1'b0 ; 
		
	end 
	else begin 
	
			SinglePulse_TrapCollision <= 1'b0 ; // default 
			if(startOfFrame) 
				flag <= 1'b0 ; // reset for next time 
				

if ( collision_hero_trap && (flag == 1'b0)) begin 
			flag	<= 1'b1; // to enter only once 
			SinglePulse_TrapCollision <= 1'b1 ; 
		end ; 
 
	end 
end

endmodule

