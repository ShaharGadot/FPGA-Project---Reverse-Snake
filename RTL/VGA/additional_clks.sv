
module	additional_clks	(	
					input		logic	clk,
					input		logic startOfFrame,
					input		logic	resetN,
					input    logic [3:0] slow_time_countdown,

		 

			  
				   output	logic	motion_pulse,
				   output	logic	motion_clk,
					output	logic one_sec_pulse

);

logic [4:0] motion_counter;
logic [24:0] sec_counter;

parameter int frames_per_motion = 16;
parameter int clks_per_sec = 31500000;
int crnt_frames_per_motion;
int crnt_clks_per_sec;

assign crnt_frames_per_motion = (slow_time_countdown != 4'd0) ? (crnt_frames_per_motion * 2) : crnt_frames_per_motion;
assign crnt_clks_per_sec = (slow_time_countdown != 4'd0) ? (crnt_clks_per_sec * 2) : crnt_clks_per_sec;


always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		motion_counter <= 5'h0;
		motion_pulse <= 1'b0;
		motion_clk <= 1'b0;
		one_sec_pulse <= 1'b0;
		sec_counter <= 25'd0;

	end
	
	else begin
		motion_pulse <= 1'b0;
		one_sec_pulse <= 1'b0;
		
		if (startOfFrame) begin
			motion_counter <= motion_counter + 1'b1;
			
			if (motion_counter == crnt_frames_per_motion - 1) begin
			
				motion_counter <= 5'h0;
				motion_pulse <= 1'b1;
				motion_clk <= !motion_clk;
			end
		end
			

		sec_counter <= sec_counter + 1'b1;
		
		if (sec_counter == crnt_clks_per_sec - 1) begin	
			sec_counter <= 25'd0;
			one_sec_pulse <= 1'b1;
		end
		
			
	end
end	
endmodule


