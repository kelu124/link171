//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     13:47:25 07/27/2015  
// Module Name:     coarse_syn_Statistics 
// Project Name:    Rx synchronization correlation process;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     ����Ƶ��ͬ�����������ͳ�Ƽ��㣬������ͬ��ʱ�����壬����״̬����ͬ��ת��
//                 
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// threshold:����·�ܺ��������ֵʱ��Ϊͬ���ɹ�
// ��ͬ�����ƻ��ƣ�����һ������ʶ���Ϻ�û����ʶ�����ֵı���ʱ�䣬������3�����֣�����cnt_channal�����־
//
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps


module coarse_syn_statistics
(
//// clock/reset ////
input               logic_clk_in,		//200m
input               logic_rst_in,

input[2:0]          threshold,
input[3:0]          coarse_code_num,
input               correlate_success_all,
input[5:0]          correlate_peak_all,

output[4:0]         coarse_position_out,
output              coarse_syn_success_out,

//// debug ////
output [63:0]      debug_signal
);

//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
reg [6:0]           cnt_m                  = 7'd0;  
reg [6:0]           cnt_n                  = 7'd0;     
reg                 clc                    = 1'b0;
reg [2:0]           cnt_channal            = 3'd0;
                                           
reg [4:0]           coarse_position        = 5'd0;
reg                 coarse_syn_success     = 1'b0;

reg                 coarse_dly_en          = 1'b0;                           
reg [13:0]          coarse_dly_cnt         = 14'd0;     
reg                 coarse_syn_success_reg = 1'b0;

reg [13:0]          coarse_dly_length      = 14'd0;

//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////
//parameter coarse_dly_length = ((5'd3 - coarse_position[4:0])*2600) - 1;

//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment //
//assign coarse_position_out[4:0]            = coarse_position[4:0];
//assign coarse_syn_success_out              = coarse_syn_success;
assign coarse_position_out[4:0]            = 5'd3;
assign coarse_syn_success_out              = coarse_syn_success_reg;

//////////////////////////////////////////////////////////////////////////////////
////(1)Synchronization error suppression mechanism
//��ͬ�����ƻ��ƣ�����һ������ʶ���Ϻ�û����ʶ�����ֵı���ʱ�䣬������3�����֣�����cnt_channal�����־
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
	    begin
		cnt_m[6:0]                           <= 7'd0;
		cnt_n[6:0]                           <= 7'd0;
		clc                                  <= 1'd0;
		end                             
	else
	    begin
			if(cnt_m[6:0] == 7'd36 && cnt_n[6:0] == 7'd63)      //3������ 40*3*40(3code*32bit*40clk+sync delay 8clk)=120*40= 4800;4800/128=37.5   
			    begin
				cnt_m[6:0]               <= 7'd0;
		        cnt_n[6:0]               <= 7'd0;
				clc                      <=1'd1;
				end
			else
			    begin
				clc <= 1'd0;
			    if(correlate_success_all)
				    begin
					cnt_m[6:0]           <= 7'd0;
		            cnt_n[6:0]           <= 7'd0;
					end
				else
				    begin
                    cnt_n[6:0]           <= cnt_n[6:0] + 1'd1;						
					if(cnt_n[6:0] == 7'd127)
					    cnt_m[6:0]       <= cnt_m[6:0] + 1'd1;
					else            
					    cnt_m[6:0]       <= cnt_m[6:0];
					end
				end

		end
end
						
//////////////////////////////////////////////////////////////////////////////////
////(2)Synchronization decision mechanism 
////ͬ��·������2��>=3����Ϊͬ���ɹ������������һ�����success�źţ�ͬ��λ�ù̶���3
always@(posedge logic_clk_in)
begin
		if(logic_rst_in) begin
				coarse_position[4:0]                <= 5'd0;
				cnt_channal[2:0]                    <= 3'd0;
				coarse_syn_success                  <= 1'b0;
		end                                     
		else  begin                                   
			if(clc) begin                               
				coarse_position[4:0]                <= 5'd0;
				cnt_channal[2:0]                    <= 3'd0;
				coarse_syn_success                  <= 1'b0;
			end                                 
			else begin			                        
				case(coarse_code_num[3:0])               
			    4'd0:begin                              
					cnt_channal[2:0]                <= cnt_channal[2:0];
					coarse_syn_success              <= 1'b0;
				end
			    4'd1:begin
					if(cnt_channal[2:0] == (threshold[2:0]-1'b1))
						begin
							coarse_position[4:0]    <= 5'd0;
							cnt_channal[2:0]        <= 3'd0;
							coarse_syn_success      <= 1'b1;
						end
					else
						begin
							cnt_channal[2:0]        <= cnt_channal[2:0] +3'd1;
							coarse_syn_success      <= 1'b0;
						end
				end
			    4'd2:begin
					if(cnt_channal[2:0] == (threshold[2:0]-1'b1))
						begin
							coarse_position[4:0]    <= 5'd1;
							cnt_channal[2:0]        <= 3'd0;
							coarse_syn_success      <= 1'b1;
						end
					else
						begin
							cnt_channal[2:0]        <= cnt_channal[2:0] +3'd1;
							coarse_syn_success      <= 1'b0;
						end
				end
			    4'd3:begin					
					if(cnt_channal[2:0] == (threshold[2:0]-1'b1))
						begin
							coarse_position[4:0]    <= 5'd2;
							cnt_channal[2:0]        <= 3'd0;
							coarse_syn_success      <= 1'b1;
						end
					else
						begin
							cnt_channal[2:0]        <= cnt_channal[2:0] +3'd1;
							coarse_syn_success      <= 1'b0;
						end
				end
			    4'd4:begin					
					if(cnt_channal[2:0] == (threshold[2:0]-1'b1))
						begin
							coarse_position[4:0]    <= 5'd3;
							cnt_channal[2:0]        <= 3'd0;
							coarse_syn_success      <= 1'b1;
						end
					else
						begin
							cnt_channal[2:0]        <= cnt_channal[2:0] +3'd1;
							coarse_syn_success      <= 1'b0;
						end
				end
			    default:
				    begin
				    	    coarse_position[4:0]    <= coarse_position[4:0];
				    	    cnt_channal[2:0]        <= 3'd0;
				    	    coarse_syn_success      <= 1'b0;
				    end
			    endcase			
			end
		end
end
	
// always @(posedge logic_clk_in)
// begin
    // if(logic_rst_in) begin
		// coarse_dly_length[13:0]           <= 14'd0;
    // end 
	// else if(coarse_syn_success && (coarse_position[4:0] == 5'd3)) begin                  
		// coarse_dly_length[13:0]           <= 14'd0;
    // end 
	// else if(coarse_syn_success && (coarse_position[4:0] != 5'd3)) begin                  
		// coarse_dly_length[13:0]           <= ((5'd3 - coarse_position[4:0])*2600) - 1'b1;
    // end 
    // else if(coarse_dly_cnt[13:0] == coarse_dly_length[13:0])begin 
		// coarse_dly_length[13:0]           <= 14'd0;
    // end	                            
// end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
		coarse_dly_length[13:0]               <= 14'd0;
    end 
	else if(coarse_syn_success) begin  
        case (coarse_position[4:0])	
		  5'd0: begin
		    coarse_dly_length[13:0]           <= 14'd7799;
		  end
		  5'd1: begin
		    coarse_dly_length[13:0]           <= 14'd5199;
		  end
		  5'd2: begin
		    coarse_dly_length[13:0]           <= 14'd2599; //((5'd3 - coarse_position[4:0])*2600) - 1'b1;
		  end
		  5'd3: begin
		    coarse_dly_length[13:0]           <= 14'd0;
		  end
		  default: begin
		    coarse_dly_length[13:0]           <= coarse_dly_length[13:0];
		  end	  
		endcase
	end
end
		  
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        coarse_dly_en                     <= 1'b0;
    end 
	else if(coarse_syn_success) begin                  
        coarse_dly_en                     <= 1'b1;
    end 
    else if(coarse_dly_cnt[13:0] == coarse_dly_length[13:0])begin 
        coarse_dly_en                     <= 1'b0;
    end	                          
end
	
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        coarse_dly_cnt[13:0]              <= 14'd0;
    end 
    else if(coarse_dly_cnt[13:0] == coarse_dly_length[13:0])begin 
        coarse_dly_cnt[13:0]              <= 14'd0;
    end	
	else if(coarse_dly_en) begin                  
        coarse_dly_cnt[13:0]              <= coarse_dly_cnt[13:0] + 1'b1;
    end                              
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        coarse_syn_success_reg            <= 1'b0;
    end 
    else if(coarse_dly_en && (coarse_dly_cnt[13:0] == coarse_dly_length)) begin 
        coarse_syn_success_reg            <= 1'b1;
    end	
	else begin                
        coarse_syn_success_reg            <= 1'b0;
    end                              
end
	
//////////////////////////////////////////////////////////////////////////////////
//// debug ////
assign  debug_signal[6:0]                 = cnt_m[6:0]; 
assign  debug_signal[13:7]                = {1'b0,correlate_peak_all[5:0]};//cnt_n[6:0]; 
assign  debug_signal[14]                  = clc;
assign  debug_signal[15]                  = correlate_success_all;
assign  debug_signal[19:16]               = coarse_code_num[3:0];
assign  debug_signal[22:20]               = cnt_channal[2:0]; 
assign  debug_signal[23]                  = coarse_syn_success;
assign  debug_signal[28:24]               = coarse_position[4:0];
assign  debug_signal[29]                  = coarse_dly_en;
assign  debug_signal[30]                  = coarse_syn_success_out;
assign  debug_signal[31]                  = 1'b0;


assign  debug_signal[63:46]               = 18'd0; 


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule 