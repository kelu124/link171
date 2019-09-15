////////////////////////////////////////////////////////////////////////////////
// Company: <Company Name>
// Engineer: <Engineer Name>
//
// Create Date: <date>
// Design Name: <name_of_top-csvel_design>
// Moducs Name: <name_of_this_moducs>
// Target Device: <target device>
// Tool versions: <tool_versions>
// Description:
//  
// Dependencies:
//    <Dependencies here>
// Revision:
//    <Code_revision_information>
// Additional Comments:
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module lmk_spi(

input               clk_in,
input               rst_in,
//------------
input               spi_stat,
input[31:0]         spi_data_in,
input               spi_red_en,
input[6:0]          spi_number,
input               spi_wr_en,
//
output              spi_clk,
output reg          spi_cs,	 
output              spi_sdi,	 
input               spi_sdo, 
//output                spi_sdo,

output              spi_rend,
output              spi_wend,
output              spi_data_valid,
output [31:0]       spi_data_out,
output reg [6:0]        spi_count_starte,	 




output [63:0]           debug_signal


);



//////////////////////////////////////////////////////////////////////////////////
//// signal declaration    ////
reg [6:0]           spi_cs_cnt = 14'd0;
reg [31:0]          spi_reg ;

reg                 spi_data = 1'd0;
reg                 spi_cs_n = 1'd0;
reg                 spi_cs_n1 ;
reg                 spi_cs_reg ;
reg                 lmk_red_end;
reg                 lmk_wr_end;

reg                 lmk_red_en;
reg [6:0]           lmk_red_cnt;
reg                 lmk_red_cs;
reg                 spi_repeat;
reg [27:0]          spi_rd_data_sdo;
reg [31:0]          microwire_rd_data;
reg                 microwire_rd_valid;
//wire                spi_clk_bfmx;
reg [4:0]           addr_reg;


//////////////////////////////////////////////////////////////////////////////////
//// parameter ////



//////////////////////////////////////////////////////////////////////////////////
//// signal assignment ////
   //    assign  spi_clk     = spi_cs ? 1'd0 : clk_in; 
        assign  spi_clk     =  clk_in; 
       
       
      // assign  spi_sdo                = 1'b1;

       assign  spi_sdi     = spi_data;
              
//   BUFGMUX #(
//      .CLK_SEL_TYPE("SYNC")  // Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
//   )
//   BUFGMUX_inst (
//      .O(spi_clk_bfmx),   // 1-bit output: Clock buffer output
//      .I0(clk_in     ),   // 1-bit input: Clock buffer input (S=0)
//      .I1(1'd0       ),   // 1-bit input: Clock buffer input (S=1)
//      .S(spi_cs_n1   )    // 1-bit input: Clock buffer select
//   );              
              
              
              
              
              
              
       assign  spi_rend     = lmk_red_end;  
		   assign  spi_wend     = lmk_wr_end;
       
       assign  spi_data_out   = microwire_rd_data;
       assign  spi_data_valid = microwire_rd_valid;
       
       
//////////////////////////////////////////////////////////////////////////////////
//// (0) SPI cs ////
always@(negedge clk_in)
begin
     if(!spi_cs_n1 || !lmk_red_cs)
       spi_cs = 1'd0;
     else
       spi_cs = 1'd1;
end
      
//////////////////////////////////////////////////////////////////////////////////
//// (1) SPI cs ////
always@(negedge clk_in or posedge rst_in)
begin
	if (rst_in)
		 spi_cs_n <= 1'd0;
  else if(spi_stat || spi_repeat)
     spi_cs_n <= 1'd1;
  else if(spi_cs_cnt == 7'd31)
     spi_cs_n <= 1'd0;
end       
//////////////////////////////////////////////////////////////////////////////////
//// () SPI CS ////
always@(negedge clk_in or posedge rst_in)
begin
  if (rst_in)begin
  	spi_cs_n1   <= 1'd1;
    spi_cs_reg  <= 1'b1;
  end
  else begin
  	spi_cs_n1   <=  ~spi_cs_n;
    spi_cs_reg  <= spi_cs_n1;        
  end
end       
//////////////////////////////////////////////////////////////////////////////////
//// () SPI cs cnt ////
always@(negedge clk_in or posedge rst_in)
begin
	if (rst_in)
		 spi_cs_cnt <= 7'd0;
  else if(spi_cs_n)
     spi_cs_cnt <= spi_cs_cnt + 1'd1;
  else 
     spi_cs_cnt <= 7'd0;  
end	  
//////////////////////////////////////////////////////////////////////////////////
//// () SPI data ////
always@(negedge clk_in or posedge rst_in)
begin
	if (rst_in)
		 spi_reg <= 72'd0;           
  else if(spi_stat)     
     spi_reg <= 72'd0; 
  else if(spi_cs_cnt == 7'd0)
     spi_reg <= spi_data_in;
  else 
     spi_reg[31:1] <= spi_reg[30:0];
end        
//////////////////////////////////////////////////////////////////////////////////
//// () SPI w 并串////
always@(negedge clk_in or posedge rst_in)
begin
  if (rst_in)
    spi_data  <= 1'b0;
  else if(!lmk_red_cs)
    spi_data  <= 1'b1;
  else 
    spi_data  <= spi_reg[31];  
end	       



//////////////////////////////////////////////////////////////////////////////////
//// () 寄存器读
always@(negedge clk_in or posedge rst_in)
begin
  if (rst_in)
    addr_reg  <= 5'd0;
   else if(spi_cs_cnt == 7'd0)
    addr_reg  <= spi_data_in[20:16];
end	 





//////////////////////////////////////////////////////////////////////////////////
//// () LMK   读////
always@(negedge clk_in or posedge rst_in)
begin
  if (rst_in)
    lmk_red_en <= 1'd0;
  else if(lmk_red_cnt == 7'd35 || lmk_red_end || spi_wr_en)
    lmk_red_en <= 1'd0;	 
  else if(spi_cs_n1 && !spi_cs_reg && spi_red_en)
    lmk_red_en <= 1'd1;
  else
    lmk_red_en <= lmk_red_en;
end
//////////////////////////////////////////////////////////////////////////////////
//// () LMK   读////
always@(negedge clk_in or posedge rst_in)
begin
  if (rst_in)
    lmk_red_cnt <= 7'd0;
  else if(lmk_red_en)
    lmk_red_cnt <= lmk_red_cnt + 7'd1;
  else
    lmk_red_cnt <= 7'd0;
end    
//////////////////////////////////////////////////////////////////////////////////
//// () LMK   读////
always@(negedge clk_in or posedge rst_in)
begin
  if (rst_in)
    lmk_red_cs <= 1'd1;
  else if(lmk_red_cnt == 7'd1)
    lmk_red_cs <= 1'd0;
  else if(lmk_red_cnt == 7'd29)
    lmk_red_cs <= 1'd1;
  else
    lmk_red_cs <= lmk_red_cs;
end 
//////////////////////////////////////////////////////////////////////////////////
//// () LMK   窗口时间控制，单写优先级最高，读完，初始化优先级最低。
always@(negedge clk_in or posedge rst_in)
begin
  if (rst_in)
    spi_count_starte <= 7'd0;
 // else if(spi_count_starte == spi_number && ((spi_cs_n1 && !spi_cs_reg) || lmk_red_end) || lmk_wr_end||(spi_stat && spi_wr_en))
  else if(spi_count_starte == spi_number && ((spi_cs_n1 && !spi_cs_reg) || lmk_red_end) || lmk_wr_end)
    spi_count_starte <= 7'd0;
  else if(spi_wr_en)begin  
  	    if(spi_cs_n1 && !spi_cs_reg)
  	      spi_count_starte <= spi_count_starte + 7'd1;  
  	    else
  	      spi_count_starte <= spi_count_starte;
  end    
  else if(spi_red_en)begin
  	      if(lmk_red_cnt == 7'd28 )
  	         spi_count_starte <= spi_count_starte + 7'd1;
  	      else
  	         spi_count_starte <= spi_count_starte;
  end
  else if(spi_cs_n1 && !spi_cs_reg)
  	     spi_count_starte <= spi_count_starte + 7'd1;  
  else
  	spi_count_starte <= spi_count_starte;
end  
  
  
//////////////////////////////////////////////////////////////////////////////////
//// () LMK  SPI重新启动信号
always@(negedge clk_in or posedge rst_in)
begin
  if (rst_in || (spi_count_starte == spi_number))
    spi_repeat <= 1'd0;
  else if(spi_wr_en)begin  
  	    if(spi_cs_n1 && !spi_cs_reg)
  	        spi_repeat <= 1'd1;
  	    else
  	        spi_repeat <= 1'd0;
  end    
  else if(spi_red_en)begin
  	      if(lmk_red_cnt == 7'd35 )
  	         spi_repeat <= 1'd1;
  	      else
  	         spi_repeat <= 1'd0; 	    
  end    
  else if(spi_cs_n1 && !spi_cs_reg)
          spi_repeat <= 1'd1;
  else
    spi_repeat <= 1'd0;
end
//////////////////////////////////////////////////////////////////////////////////
//// (*) SPI red  读出数据串并////
always@(negedge clk_in or posedge rst_in)
begin
  if (rst_in)
    spi_rd_data_sdo[27:0] <= 28'd0;  	
  else if(spi_stat || !spi_red_en || lmk_red_cnt == 7'd1)
    spi_rd_data_sdo      <= 28'd0;  
  else if(spi_red_en && !spi_cs)
    spi_rd_data_sdo      <={spi_rd_data_sdo[26:0],spi_sdo};
  else
    spi_rd_data_sdo      <= spi_rd_data_sdo;
end    
//////////////////////////////////////////////////////////////////////////////////
//// (*)                                           ////
always@(negedge clk_in or posedge rst_in)
begin
  if(rst_in)
     microwire_rd_data  <= 32'd0;
  else if(lmk_red_cnt == 7'd30)
     microwire_rd_data <= {spi_rd_data_sdo,addr_reg};
  else
     microwire_rd_data <= microwire_rd_data;
end     
//////////////////////////////////////////////////////////////////////////////////
//// (*)                                           ////
always@(negedge clk_in or posedge rst_in)
begin
  if(rst_in)
     microwire_rd_valid  <= 1'd0;
  else if(lmk_red_cnt == 7'd30)
     microwire_rd_valid  <= 1'd1;
  else
     microwire_rd_valid  <= 1'd0;
end 
//////////////////////////////////////////////////////////////////////////////////
//// (*)                                           ////
always@(negedge clk_in or posedge rst_in)
begin
  if(rst_in)
     lmk_red_end  <= 1'd0;
  else if(spi_count_starte == spi_number &&  lmk_red_cnt == 7'd30)
     lmk_red_end  <= 1'd1;
  else
     lmk_red_end  <= 1'd0;
end  
 //////////////////////////////////////////////////////////////////////////////////
//// (*)                                           ////
always@(negedge clk_in or posedge rst_in)
begin
  if(rst_in)
     lmk_wr_end  <= 1'd0;
  else if(spi_wr_en &&  spi_cs_n1 && !spi_cs_reg && spi_count_starte == 7'd2)
     lmk_wr_end  <= 1'd1;
  else if(spi_cs_n1 && !spi_cs_reg && spi_count_starte == spi_number)
     lmk_wr_end  <= 1'd1;
  else
     lmk_wr_end  <= 1'd0;
end
 
 
 
//////////////////////////////////////////////////////////////////////////////////
//// debug signal ////
assign  debug_signal[63:0]             = {spi_red_en,
                                           24'd0,
                                          spi_red_en,
                                          spi_sdo,
                                          spi_data,
                                          spi_stat,                                         
                                          spi_cs,
                                          lmk_red_cnt[6:0],                                       
                                          spi_rd_data_sdo                                          
                                          }; 
 
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule 
 
 
 
 
 
 
 
 
       