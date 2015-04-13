// A2D Interface

module A2D_intf(clk,rst_n,strt_cnv,cnv_cmplt,chnnl,res,a2d_SS_n,SCLK,MOSI,MISO);

	input clk,rst_n,strt_cnv,MISO;
	input [2:0] chnnl;
	output cnv_cmplt,a2d_SS_n,SCLK,MOSI;
	output [11:0] res;

	reg unsigned [4:0] clk_cntr;	// counts half of an SCLK period
	reg a2d_ss_n;
	reg strt_cnv_FLTRD;
	reg [15:0] shift_reg;
	reg SHIFT_NOW;
	reg SCLK;
	reg unsigned [5:0]shft_cntr;
	reg cnv_cmplt;
	reg q1,q2;

	//strt_cnv signal conditioning - Flops//
	always @ (posedge clk, negedge rst_n)
	  if(!rst_n)begin
	    q1 <= 1'b0;
	    q2 <= 1'b0;
		end
	  else begin
	    q1 <= strt_cnv;
	    q2 <= q1;
		end
		
	assign strt_cnv_FLTRD = q1 & q2;

	//a2d_SS_n//
	assign a2d_SS_n = cnv_cmplt;   //**?**

	//res[11:0]//
	assign res = ~shift_reg[11:0];

	///clk_cntr///
	always @ (posedge clk, rst_n)
		if(!rst_n) begin
		  clk_cntr <= 4'h0;
		  SHIFT_NOW <= 1'b0;
			end
		else if (clk_cntr == 4'b1111)begin
		   SHIFT_NOW <= 1'b1;			//signal to shift 1 clk before falling edge
		   clk_cntr <= clk_cntr + 1;
			end
		else begin
		   clk_cntr <= clk_cntr + 1;
		   SHIFT_NOW <= 1'b0;
			end
	//shft_cntr//
	always @ (posedge SHIFT_NOW, negedge rst_n)
		if(!rst_n)
		  shft_cntr <= 5'b0_0000;
		else if (SHIFT_NOW)
		  shft_cntr <= shft_cntr + 1;
		else shft_cntr <= shft_cntr;

		
	//SCLK//
	  always @ (posedge clk_cntr)
		if (!rst_n)
		   SCLK <= 1'b1;
		else if (clk_cntr == 4'b0000)
		   SCLK <= ~SCLK;
		else if (shft_cntr == 5'b0_0000 & !strt_cnv)			//idle condition?
		   SCLK <= 1'b1;
		else
		   SCLK <= SCLK;

	//cnv_cmplt//
	always @ (posedge strt_cnv_FLTRD, shft_cntr)
		if(strt_cnv_FLTRD)
		cnv_cmplt = 1'b0;
		else if (shft_cntr !== 5'b0_0000)
		cnv_cmplt = 1'b0;
		else cnv_cmplt = 1'b1;

	//shift_reg
	always @ (SHIFT_NOW, strt_cnv_FLTRD)
	   if(SHIFT_NOW)
		shift_reg <= {shift_reg[14:0],MISO};
	   else if(strt_cnv_FLTRD)					//idle/start condition?
		shift_reg <= {2'b00,chnnl,11'b000};
	   else 
		shift_reg <= shift_reg;

	//MOSI
	assign MOSI = shift_reg[15];

	endmodule
	
