
// game controller dudy Febriary 2020
// (c) Technion IIT, Department of Electrical Engineering 2021 
//updated --Eyal Lev 2021

module	game_controller	(	
			input	logic	clk,
			input	logic	resetN,
			input	logic	startOfFrame,  // short pulse every start of frame 30Hz
		
		
			input	logic	[1:0] GridDrawingRequest,	
			input	logic	HeroDrawingRequest,

			
			output logic collision_hero_trap, // collisions are active in case of collision between objects
			output logic collision_hero_border,

			output logic SinglePulse_TrapCollision //generating A single pulse in a frame in trap collision 
			
);

logic BorderDrawingRequest;
logic TrapDrawingRequest;

assign BorderDrawingRequest = GridDrawingRequest[0];
assign TrapDrawingRequest = GridDrawingRequest[1];



logic flag ; // a semaphore to set the output only once per frame regardless of number of collisions 


assign collision_hero_trap = (TrapDrawingRequest && HeroDrawingRequest);
assign collision_hero_border = (BorderDrawingRequest && HeroDrawingRequest);



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

