

/*
typedef struct packed {
    logic [3:0] note;
    logic [2:0] octave;
    logic [7:0] duration;
    logic [7:0] gap;
} note_struct;
*/

localparam int NOTES_IN_A_SONG = 256;
localparam int SOUND_MEM_SIZE = 4096;
localparam int SOUND_ADDR_W = $clog2(SOUND_MEM_SIZE);

typedef logic [SOUND_ADDR_W-1:0] song_addr_t; 

module melody_player_1
    (
    // Declare wires and regs :
 input logic resetN,
 input logic CLOCK_31p5,
 input logic startMelody,
 input logic [3:0] melodySelect, // selector of one melody  
 input logic stopMelody,

// input logic [15:0] songs_mem,		// input from songs.mif
 
 output logic [3:0] tone,
 output logic [2:0] octave,
 output logic EnableSoundOut,		// controls AUDIO module on/off 
 output logic melodyEnded       // indicates end of melody.  Also outputs to LED3      
 //output logic [11:0] note_address // output to audio MIF address 
 
  );   // serial number of current note. ( maximum 31 ). noteIndex determines freqIndex and note_length, via JueBox
 
 // songs.vh contain a table of songs, including note_base, octave, duration and gap	
//`include "songs.sv"

 // Maestro state machine declaration 
 enum logic [1:0] {s_idle, s_playNote, s_gap, s_ended} SM_Maestro; // state machine

	// parameters declarations
	logic [11:0] note_address;
	 logic [15:0] songs_mem;
	logic [4:0] noteTimeCounter; // count down timer ( maximum 1024 )
   logic [4:0] noteDuration;    
   logic [4:0] gapDuration;     // time of gap between notes in msec
   logic hundredthSecPulse; // A short pulse, once every 1/100 second. 

	// interface signals to the list of songs
	logic [7:0] noteIndex;
	
	logic [3:0] melodySelect_reg;
	
	lpm_rom #(
    .LPM_WIDTH(16),
    .LPM_WIDTHAD(12),
	 .LPM_NUMWORDS(4096),
    .LPM_FILE("RTL/AUDIO/songs.mif"),
	   .LPM_TYPE               ("LPM_ROM"),
      .LPM_ADDRESS_CONTROL    ("REGISTERED"), 
		.LPM_OUTDATA            ("UNREGISTERED"), 
		.AUTO_CARRY_CHAINS      ("ON"),
		.AUTO_CASCADE_BUFFERS   ("ON"),
	   .INTENDED_DEVICE_FAMILY ("Cyclone V")  
) rom_inst (
    .address(note_address),
	 .inclock(CLOCK_31p5),
	// .outclock(clk),
    .q(songs_mem)
);
  //----------------------------------------------------------------------------------------------------------
  // Instances of slow counter.  pulse every 10 mSec
  //----------------------------------------------------------------------------------------------------------									  									  								 
   Mili_sec_counter #(.SIMULATION_MODE(1'h0), .mSecPerTick(30), .PLLClock(315)) mili_sec_counter_inst 
	                     (.clk(CLOCK_31p5),   
								 .resetN(resetN),
								 .turbo(1'h0),   
								 .hundredth_sec(hundredthSecPulse) );
								 
	//----------------------------------------------------------------------------------------------------------								 					 	 
	//   syncronous code,  executed once every clock to update the current state and outputs 
	//----------------------------------------------------------------------------------------------------------	
	always_ff @(posedge CLOCK_31p5 or negedge resetN) begin   
    if ( !resetN ) begin 
        SM_Maestro <= s_idle;
        noteIndex <= 8'b0;
        noteTimeCounter <= 5'b0;
        EnableSoundOut <= 1'b0;
        melodyEnded <= 1'b0;
        melodySelect_reg <= 4'b0;
    end
    else begin     
        EnableSoundOut <= 1'b0;
        melodyEnded <= 1'b0;

        case ( SM_Maestro )			
               s_idle: begin
                   noteIndex <= 8'b0;
                   if (startMelody) begin   
                       melodySelect_reg <= melodySelect;
                       SM_Maestro <= s_playNote;    
                   end
               end
               
               s_playNote: begin	
                   EnableSoundOut <= 1'b1; 
                   
                   if (stopMelody) begin  // if we want to stop the melody
                       noteTimeCounter <= 5'b0;
                       SM_Maestro <= s_ended;     
                   end
                   else if (startMelody) begin  // if we want to play new melody during another
                       melodySelect_reg <= melodySelect; 
                       noteIndex <= 8'b0;            
                       noteTimeCounter <= 5'b0;   
                       SM_Maestro <= s_playNote;  
                   end
                   else begin
                       if (noteTimeCounter == 5'b0) begin
                           noteTimeCounter <= noteDuration;
                       end
                       
                       if (noteDuration != 5'b0) begin    
                           if ( hundredthSecPulse ) begin
                               noteTimeCounter <= noteTimeCounter - 5'b1; 
                           end
                           if (noteTimeCounter == 5'b1 && hundredthSecPulse) begin
                               noteIndex <= noteIndex + 1'b1;   
                               SM_Maestro <= s_gap;   
                               noteTimeCounter <= gapDuration; 
                           end 
                       end    
                       else begin
                           SM_Maestro <= s_ended;
                       end
                   end
               end
               
               s_gap : begin	
                   if (stopMelody) begin  // if we want to stop the melody
                       noteTimeCounter <= 5'b0;
                       SM_Maestro <= s_ended;
                   end
                   else if (startMelody) begin    // if we want to play new melody during another
                       melodySelect_reg <= melodySelect; 
                       noteIndex <= 8'b0;                
                       noteTimeCounter <= 5'b0;          
                       SM_Maestro <= s_playNote;
                   end
                   else begin
                       if ( hundredthSecPulse ) begin
                           noteTimeCounter <= noteTimeCounter - 5'b1;   
                       end
                       if (noteTimeCounter == 5'b0) begin 
                           SM_Maestro <= s_playNote;      
                           noteTimeCounter <= noteDuration;     
                       end 
                   end
               end
               
               s_ended : begin
                   melodyEnded <= 1'b1;   
                   SM_Maestro <= s_idle;  
               end
               
               default: SM_Maestro <= s_idle;
           endcase
    end
end

	//assign song_index  = base_offset + noteIndex;
	//assign note_address[11:8] = melodySelect;
	//assign note_address[7:0] = noteIndex;
assign note_address = {melodySelect_reg, noteIndex};
//	assign tone        	= all_songs[song_index].note;
//	assign octave      	= all_songs[song_index].octave;
//	assign noteDuration  = all_songs[song_index].duration;	// in units of ? msec
//	assign gapDuration  	= all_songs[song_index].gap;		   // in units of ? msec

	assign tone        	= songs_mem[15:12];  
	assign octave   		= {{1'b0},{songs_mem[11:10]}} + 3'd3; 
	assign noteDuration  = songs_mem[9:5];
	assign gapDuration  	= songs_mem[4:0];
endmodule

