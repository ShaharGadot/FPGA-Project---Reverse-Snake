
// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018

//-- Eyal Lev 31 Jan 2021

module	objects_mux	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
		 
					     
					input		logic	HeroDrawingRequest,
					input		logic	[7:0] HeroRGB, 
			  
		  ////////////////////////
		  // background 
					input		logic	[1:0] GridDrawingRequest, 
					input		logic	[7:0] GridRGB, 
					
					
					input		logic	[7:0] BackGroundRGB, 
			  
				   output	logic	[7:0] RGBOut
);

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		
		if (HeroDrawingRequest == 1'b1)
				RGBOut <= HeroRGB;
 	
		else if (GridDrawingRequest != 2'b0)
				RGBOut <= GridRGB ;
				
		else RGBOut <= BackGroundRGB ;// last priority 
		end ; 
	end

endmodule


