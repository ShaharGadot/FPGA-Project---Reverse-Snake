
module	motion_clk	(	
					input		logic	clk,
					input		logic startOfFrame,
					input		logic	resetN,
		 

			  
				   output	logic	motion_pulse,
				   output	logic	motion_clk


);

logic [4:0] counter;
parameter int frames_per_motion = 10;

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		counter <= 5'h0;
		motion_pulse <= 1'b0;
		motion_clk <= 1'b0;

	end
	
	else begin
		motion_pulse <= 1'b0;
		
		if (startOfFrame) begin
			counter <= counter + 1'b1;
			
			if (counter == frames_per_motion - 1) begin
			
				counter <= 5'h0;
				motion_pulse <= 1'b1;
				motion_clk <= !motion_clk;
			end
		end
			
	end
end	
endmodule


