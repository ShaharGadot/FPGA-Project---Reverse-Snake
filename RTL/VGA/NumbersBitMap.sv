//
// coding convention dudy December 2018
// (c) Technion IIT, Department of Electrical Engineering 2025
// generating a number bitmap 



module NumbersBitMap	(	
					input		logic	clk,
					input		logic	resetN,
					input 	logic	[10:0] offsetX,// offset from top left  position 
					input 	logic	[10:0] offsetY,
					input		logic	InsideRectangle, //input that the pixel is within a bracket 
					input 	logic	[3:0] digit, // digit to display
					
					output	logic				drawingRequest, //output that the pixel should be dispalyed 
					output	logic	[7:0]		RGBout
);


localparam logic[12:0] OBJECT_WIDTH_X = 6'd32;
localparam logic[12:0] OBJECT_WIDTH_Y = 6'd32;
localparam logic[12:0] digit_location_MIF = OBJECT_WIDTH_X*OBJECT_WIDTH_Y;

// generating a number bitmap from a MIF file
logic [9:0] address  ;
logic [7:0] color  ;
localparam logic [7:0] TRANSPARENT_ENCODING = 8'hFF ;// RGB value in the bitmap representing a transparent pixel 

 
//assign address = ((digit_location_MIF*digit)+((offsetY>>1)*OBJECT_WIDTH_X + (offsetX>>1))); //***Double size
assign address = ((digit_location_MIF*digit)+((offsetY)*OBJECT_WIDTH_X + (offsetX))); //Origimal size of digit


parameter  logic	[7:0] digit_color = 8'hff ; //set the color of the digit 

lpm_rom #(
    .LPM_WIDTH(8),
    .LPM_WIDTHAD(10),
	 .LPM_NUMWORDS(1024),
    .LPM_FILE("RTL/hero_front_1.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst (
    .address(address),
	 .inclock(clk),
	// .outclock(clk),
    .q(color)
);

// pipeline (ff) to get the pixel color from the array 	 

always_ff@(posedge clk or negedge resetN)
begin
	if(!resetN) begin
		RGBout <= TRANSPARENT_ENCODING ;
	end
	
	else begin
		//drawingRequest <=	1'b0;
		RGBout <= TRANSPARENT_ENCODING ; // default  

	  	if (InsideRectangle == 1'b1 ) begin
			RGBout <= color;
		end
 	end 
end

assign drawingRequest = (RGBout != TRANSPARENT_ENCODING ) ? 1'b1 : 1'b0 ; // get optional transparent command from the bitmpap   

endmodule