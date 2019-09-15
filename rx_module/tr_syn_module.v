//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     16:49:20 07/27/2015 
// Module Name:     tr_syn_module 
// Project Name:    Rx synchronization correlation process;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;  
// Description:     ��ɶ��ź���Ѳ�����ļ��㹤����������������Ϊ25M����Ԫ����
//                  Ϊ5M��ͨ�����ź�����Ӧ��ģ���������Ӷ��õ���Ѳ���ʱ�̡� 
//
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1) 25M������������5��������ͬһ�������㣬��Ϊ��������Ϊ5M��ͬ�������5�����������ҳ���ѵĲ����㣬��Ϊ����λ�á�
// 2) һ��25M����ռ��8��clk(200M)��ÿ8��clk(25M)����һ��������������㣬ÿ40��clk(5M)����һ��tr_sync_code���ºͲ�������ֵ�ۼ�
// 3) 25Mһ�����������ʹ��16bit��ʵ���ݣ�����ÿ������ֵ��һ�������ֲ���Ч��������demsk�о���25M���ݼ��㣬25M��5�����������λһ������ֵһ�����ֲ������������ʱ�̡�
// 4)ÿһ��(13us),25M(5��������)������:
//   a0_0s0+a1_0s1+a2_0s2+....a31_0s31 (s0...s31��ÿ��ͬ�����ֵ�32��bit,s0ֻ��һ��bit)
//   a0_1s0+a1_1s1+a2_1s2+....a31_1s31 (a0_0��25M/16bit,a0(a0_0,a0_1,a0_2,a0_3,a0_4)��5M/16bit,a0-a31��6.4us)
//   a0_2s0+a1_2s1+a2_2s2+....a31_2s31
//   a0_3s0+a1_3s1+a2_3s2+....a31_3s31
//   a0_4s0+a1_4s1+a2_4s2+....a31_4s31
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module tr_syn_module(
input                logic_clk_in,           			//200m��ʱ�Ӳ���200mʱ�ӽ��д���
input                logic_rst_in,

input[15:0]          data_in,  			//�������Ǿ�����ֽ�����ģ�����ݣ�λ������
input                tr_syn_en,
input[31:0]          tr_syn_code,

output[6:0]          tr_position_out,
output               tr_syn_success_out,
output               tr_syn_finish_out,

output[127:0]        debug_signal
);

//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
reg [6:0]             tr_position          = 7'd0;
reg                   tr_syn_success       = 1'b0;
reg                   tr_syn_finish        = 1'b0;  
                    
reg [31:0]            acc_reg0             = 32'd0; //5ģ������ۼӼ���ֵ
reg [31:0]            acc_reg1             = 32'd0;  							
reg [31:0]            acc_reg2             = 32'd0;  							
reg [31:0]            acc_reg3             = 32'd0; 
reg [31:0]            acc_reg4             = 32'd0;

reg [31:0]            acc_reg5             = 32'd0; //5ģ������ۼӼ���ֵ
reg [31:0]            acc_reg6             = 32'd0;  							
reg [31:0]            acc_reg7             = 32'd0;  							
reg [31:0]            acc_reg8             = 32'd0; 
reg [31:0]            acc_reg9             = 32'd0;

reg                   tr_syn_state         = 1'b0;
reg [31:0]            tr_syn_code_reg      = 32'd0;    
reg [31:0]            tr_syn_code_reg1     = 32'd0;              
reg [11:0]            rx_bit_counter       = 12'd0;
    
reg [31:0]            max_acc_reg          = 32'd0;
reg [3:0]             max_num              = 4'd0;
reg [5:0]             digital_correlate    = 6'd0;

reg [31:0]            max_test_reg         = 32'd0;

//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////



//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
assign tr_position_out[6:0]                     = tr_position[6:0];
assign tr_syn_success_out                       = tr_syn_success;
assign tr_syn_finish_out                        = tr_syn_finish;

//////////////////////////////////////////////////////////////////////////////////
//// (1) 32��5M���ݼ�ʱ ////
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin
        tr_syn_state                            <= 1'b0;
        rx_bit_counter[11:0]                    <= 12'd0;
        end
    else
        begin
        case(tr_syn_state)
        1'b0:
            begin
            if(tr_syn_en)      							 // ����ɴ�ͬ�������Ҿ�����ʱ������ͬ�������ʱ��ʱ��en = 1��
                tr_syn_state                    <= 1'b1;
            else                                
                tr_syn_state                    <= 1'b0;
                rx_bit_counter[11:0]            <= 12'd0;
            end
        1'b1:
            begin                                   
            if(rx_bit_counter[11:0]  == 12'd2176)  //GY 32��40clk��һ��6.4us�ļ�ʱ 100010,000000; NO.33 pulseʱ�����ڱȽϷ�ֵ   
                begin
                rx_bit_counter[11:0]            <= 12'd0;
                tr_syn_state                    <= 1'b0;
                end
            else
			    if(rx_bit_counter[5:0] == 6'd39)
				    begin
					    rx_bit_counter[5:0]     <= 6'd0;
						rx_bit_counter[11:6]    <= rx_bit_counter[11:6] + 1'b1;
						tr_syn_state            <= 1'b1;
					end
				else
                    begin
                        rx_bit_counter[5:0]     <= rx_bit_counter[5:0] + 1'b1;
                        tr_syn_state            <= 1'b1;
                    end
            end
        endcase
        end
end

//////////////////////////////////////////////////////////////////////////////////
//// (2) ����5(0-31)��������ģ�����ֵ ////
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin 
        tr_syn_code_reg[31:0]                     <= tr_syn_code[31:0];
        acc_reg0[31:0]                            <= 32'd0;
		acc_reg1[31:0]                            <= 32'd0;
		acc_reg2[31:0]                            <= 32'd0;
		acc_reg3[31:0]                            <= 32'd0;
		acc_reg4[31:0]                            <= 32'd0;
        digital_correlate[5:0]                    <= 6'd0;
        end
    else
        begin
        case(tr_syn_state)
        1'b0:
            begin
            if(tr_syn_en)       
                begin 
                tr_syn_code_reg[31:0]             <= tr_syn_code[31:0]; 						// ��ȡ��ͬ���룬Ŀǰֱ�ӻ�ã�ֱ�����ⲿ������Ӧ����ֵ
                digital_correlate[5:0]            <= 6'd0;
                acc_reg0[31:0]                    <= 32'd0;
		        acc_reg1[31:0]                    <= 32'd0;
		        acc_reg2[31:0]                    <= 32'd0;
		        acc_reg3[31:0]                    <= 32'd0;
		        acc_reg4[31:0]                    <= 32'd0;
                end
            else
                begin
                tr_syn_code_reg[31:0]             <= tr_syn_code_reg[31:0];
                end
            end
        1'b1:
            begin                                  
            if((rx_bit_counter[11:6] >= 6'd0) && (rx_bit_counter[11:6] <= 6'd31) && (rx_bit_counter[2:0] == 3'd0))
                begin
                case(rx_bit_counter[5:3])                                    	 //ÿ����8�Σ�����һ��ȫ�����ݣ���������Ϊ25m����40ns, 5 sample
                3'b000:                                                         //200MHz/8=25MHz
                    begin
                    if(tr_syn_code_reg[31] == 1'b1)  						 	 //˫�����룬ģ����أ�1��ʱ��ӣ�0��ʱ����-1���Ǽ������Է�ֵ���м��
                        acc_reg0[31:0]            <= $signed(acc_reg0) + $signed(data_in);
                    else                          
                        acc_reg0[31:0]            <= $signed(acc_reg0) - $signed(data_in);
                    
					if (tr_syn_code_reg[31] == ~data_in[15])
                        digital_correlate[5:0]    <= digital_correlate[5:0] + 1'b1;
                    else                          
                        digital_correlate[5:0]    <= digital_correlate[5:0] + 1'b0;
                    end
                3'b001:
                    begin
                    if(tr_syn_code_reg[31] == 1'b1)
                        acc_reg1[31:0]            <= $signed(acc_reg1) + $signed(data_in);
                    else                                            
                        acc_reg1[31:0]            <= $signed(acc_reg1) - $signed(data_in);
                    end
                3'b010:
                    begin
                    if(tr_syn_code_reg[31] == 1'b1)
                        acc_reg2[31:0]            <= $signed(acc_reg2) + $signed(data_in);
                    else                                            
                        acc_reg2[31:0]            <= $signed(acc_reg2) - $signed(data_in);
                                                  
                    end
                3'b011:
                    begin
                    if(tr_syn_code_reg[31] == 1'b1)
                        acc_reg3[31:0]            <= $signed(acc_reg3) + $signed(data_in);
                    else                                            
                        acc_reg3[31:0]            <= $signed(acc_reg3) - $signed(data_in);
						
                    end
                3'b100:
                    begin
                    if(tr_syn_code_reg[31] == 1'b1)
                        acc_reg4[31:0]            <= $signed(acc_reg4) + $signed(data_in);
                    else                                            
                        acc_reg4[31:0]            <= $signed(acc_reg4) - $signed(data_in);
						
					tr_syn_code_reg[31:0]         <= {tr_syn_code_reg[30:0], 1'b0};	//5M shift for correlate
                    end			
                endcase
                end
			else
				begin   //��ɼ������ÿһ·�Ľ�����֣����ں����ҷ�ֵ		
					acc_reg0[31:0]                <= acc_reg0[31:0];
					acc_reg1[31:0]                <= acc_reg1[31:0];
					acc_reg2[31:0]                <= acc_reg2[31:0];
					acc_reg3[31:0]                <= acc_reg3[31:0];
					acc_reg4[31:0]                <= acc_reg4[31:0];			
					digital_correlate[5:0]        <= digital_correlate[5:0];
				end
            end
        endcase
        end
end

//////////////////////////////////////////////////////////////////////////////////
//// (2) ����5(1-32)��������ģ�����ֵ ////
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin 
		tr_syn_code_reg1[31:0]                    <= tr_syn_code[31:0];
        acc_reg5[31:0]                            <= 32'd0;
		acc_reg6[31:0]                            <= 32'd0;
		acc_reg7[31:0]                            <= 32'd0;
		acc_reg8[31:0]                            <= 32'd0;
		acc_reg9[31:0]                            <= 32'd0;
        end
    else
        begin
        case(tr_syn_state)
        1'b0:
            begin
            if(tr_syn_en)       
                begin 
				tr_syn_code_reg1[31:0]            <= tr_syn_code[31:0];
				acc_reg5[31:0]                    <= 32'd0;
		        acc_reg6[31:0]                    <= 32'd0;
		        acc_reg7[31:0]                    <= 32'd0;
		        acc_reg8[31:0]                    <= 32'd0;
		        acc_reg9[31:0]                    <= 32'd0;
                end
			else
                begin
                tr_syn_code_reg1[31:0]             <= tr_syn_code_reg1[31:0];
                end
			end
        1'b1:
            begin                                  
            if((rx_bit_counter[11:6] >= 6'd1) && (rx_bit_counter[11:6] <= 6'd32) && (rx_bit_counter[2:0] == 3'd0))
                begin
                case(rx_bit_counter[5:3])                                    	 //ÿ����8�Σ�����һ��ȫ�����ݣ���������Ϊ25m����40ns, 5 sample
                3'b000:                                                         //200MHz/8=25MHz
                    begin
                    if(tr_syn_code_reg1[31] == 1'b1)  						 	 //˫�����룬ģ����أ�1��ʱ��ӣ�0��ʱ����-1���Ǽ������Է�ֵ���м��
                        acc_reg5[31:0]            <= $signed(acc_reg5) + $signed(data_in);
                    else                       
                        acc_reg5[31:0]            <= $signed(acc_reg5) - $signed(data_in);
					end
                    
                3'b001:
                    begin
                    if(tr_syn_code_reg1[31] == 1'b1)
                        acc_reg6[31:0]            <= $signed(acc_reg6) + $signed(data_in);
                    else                                            
                        acc_reg6[31:0]            <= $signed(acc_reg6) - $signed(data_in);
                    end
					
                3'b010:
                    begin
                    if(tr_syn_code_reg1[31] == 1'b1)
                        acc_reg7[31:0]            <= $signed(acc_reg7) + $signed(data_in);
                    else                                            
                        acc_reg7[31:0]            <= $signed(acc_reg7) - $signed(data_in);
                                                  
                    end
					
                3'b011:
                    begin
                    if(tr_syn_code_reg1[31] == 1'b1)
                        acc_reg8[31:0]            <= $signed(acc_reg8) + $signed(data_in);
                    else                                            
                        acc_reg8[31:0]            <= $signed(acc_reg8) - $signed(data_in);
						
                    end
					
                3'b100:
                    begin
                    if(tr_syn_code_reg1[31] == 1'b1)
                        acc_reg9[31:0]            <= $signed(acc_reg9) + $signed(data_in);
                    else                                            
                        acc_reg9[31:0]            <= $signed(acc_reg9) - $signed(data_in);
						
					tr_syn_code_reg1[31:0]         <= {tr_syn_code_reg1[30:0], 1'b0};	//5M shift for correlate	
                    end	
					
                endcase
                end
			else
				begin   //��ɼ������ÿһ·�Ľ�����֣����ں����ҷ�ֵ		
					acc_reg5[31:0]                <= acc_reg5[31:0];
					acc_reg6[31:0]                <= acc_reg6[31:0];
					acc_reg7[31:0]                <= acc_reg7[31:0];
					acc_reg8[31:0]                <= acc_reg8[31:0];
					acc_reg9[31:0]                <= acc_reg9[31:0];			
				end
            end
        endcase
        end
end

//////////////////////////////////////////////////////////////////////////////////
//// (3) ����10���������ֵ��� ////
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin
        max_acc_reg[31:0]                         <= 32'd0;
        max_num[3:0]                              <= 4'd0;
        tr_position[6:0]                          <= 7'd0;
        tr_syn_success                            <= 1'b0;
        tr_syn_finish                             <= 1'b0;
        end
    else
        begin
        case(tr_syn_state)
        1'b0:
            begin
            max_acc_reg[31:0]                     <= 32'd0;
            max_num[3:0]                          <= 4'd0;
            tr_position[6:0]                      <= 7'd0;
            tr_syn_success                        <= 1'b0;
            tr_syn_finish                         <= 1'b0;
            end
        1'b1:
            begin       
            if((rx_bit_counter[11:6] == 6'd33 )&&(rx_bit_counter[1:0] == 2'd0) )      // ���Ѿ�������10·�����ֵ����ʼ�����ֵ
                begin
                case(rx_bit_counter[5:2])
                4'd0:
                    begin
                    if($signed(acc_reg0[31:0]) > $signed(acc_reg1[31:0]))
                        begin
                        max_acc_reg[31:0]         <= acc_reg0[31:0];
                        max_num[3:0]              <= 4'd0;
                        end
                    else
                        begin
                        max_acc_reg[31:0]         <= acc_reg1[31:0];
                        max_num[3:0]              <= 4'd1;
                        end                       
                    tr_position[6:0]              <= 7'd0;
                    tr_syn_success                <= 1'b0;  
                    tr_syn_finish                 <= 1'b0;
                    end
                4'd1:
                    begin
                    if($signed(acc_reg2[31:0]) > $signed(max_acc_reg[31:0]))
                        begin
                        max_acc_reg[31:0]         <= acc_reg2[31:0];
                        max_num[3:0]              <= 4'd2;
                        end
                    else
                        begin
                        max_acc_reg[31:0]         <= max_acc_reg[31:0];
                        max_num[3:0]              <= max_num[3:0];
                        end
                    tr_position[6:0]              <= 7'd0;
                    tr_syn_success                <= 1'b0; 
                    tr_syn_finish                 <= 1'b0;
                    end
                4'd2:
                    begin
                    if($signed(acc_reg3[31:0]) > $signed(max_acc_reg[31:0]))
                        begin
                        max_acc_reg[31:0]         <= acc_reg3[31:0];
                        max_num[3:0]              <= 4'd3;
                        end                       
                    else                          
                        begin                     
                        max_acc_reg[31:0]         <= max_acc_reg[31:0];
                        max_num[3:0]              <= max_num[3:0];
                        end
                    tr_position[6:0]              <= 7'd0;
                    tr_syn_success                <= 1'b0;                    
                    tr_syn_finish                 <= 1'b0;
                    end
				4'd3:
                    begin
                    if($signed(acc_reg4[31:0]) > $signed(max_acc_reg[31:0]))
                        begin
                        max_acc_reg[31:0]         <= acc_reg4[31:0];
                        max_num[3:0]              <= 4'd4;
                        end
                    else
                        begin
                        max_acc_reg[31:0]         <= max_acc_reg[31:0];
                        max_num[3:0]              <= max_num[3:0];
                        end
                    tr_position[6:0]              <= 7'd0;
                    tr_syn_success                <= 1'b0;                    
                    tr_syn_finish                 <= 1'b0;
                    end
				4'd4:
                    begin
                    if($signed(acc_reg5[31:0]) > $signed(max_acc_reg[31:0]))
                        begin
                        max_acc_reg[31:0]         <= acc_reg5[31:0];
                        max_num[3:0]              <= 4'd5;
                        end
                    else
                        begin
                        max_acc_reg[31:0]         <= max_acc_reg[31:0];
                        max_num[3:0]              <= max_num[3:0];
                        end
                    tr_position[6:0]              <= 7'd0;
                    tr_syn_success                <= 1'b0;                    
                    tr_syn_finish                 <= 1'b0;
                    end
				4'd5:
                    begin
                    if($signed(acc_reg6[31:0]) > $signed(max_acc_reg[31:0]))
                        begin
                        max_acc_reg[31:0]         <= acc_reg6[31:0];
                        max_num[3:0]              <= 4'd6;
                        end
                    else
                        begin
                        max_acc_reg[31:0]         <= max_acc_reg[31:0];
                        max_num[3:0]              <= max_num[3:0];
                        end
                    tr_position[6:0]              <= 7'd0;
                    tr_syn_success                <= 1'b0;                    
                    tr_syn_finish                 <= 1'b0;
                    end
				4'd6:
                    begin
                    if($signed(acc_reg7[31:0]) > $signed(max_acc_reg[31:0]))
                        begin
                        max_acc_reg[31:0]         <= acc_reg7[31:0];
                        max_num[3:0]              <= 4'd7;
                        end
                    else
                        begin
                        max_acc_reg[31:0]         <= max_acc_reg[31:0];
                        max_num[3:0]              <= max_num[3:0];
                        end
                    tr_position[6:0]              <= 7'd0;
                    tr_syn_success                <= 1'b0;                    
                    tr_syn_finish                 <= 1'b0;
                    end
				4'd7:
                    begin
                    if($signed(acc_reg8[31:0]) > $signed(max_acc_reg[31:0]))
                        begin
                        max_acc_reg[31:0]         <= acc_reg8[31:0];
                        max_num[3:0]              <= 4'd8;
                        end
                    else
                        begin
                        max_acc_reg[31:0]         <= max_acc_reg[31:0];
                        max_num[3:0]              <= max_num[3:0];
                        end
                    tr_position[6:0]              <= 7'd0;
                    tr_syn_success                <= 1'b0;                    
                    tr_syn_finish                 <= 1'b0;
                    end
				4'd8:
                    begin
                    if($signed(acc_reg9[31:0]) > $signed(max_acc_reg[31:0]))
                        begin
                        max_acc_reg[31:0]         <= acc_reg9[31:0];
                        max_num[3:0]              <= 4'd9;
                        end
                    else
                        begin
                        max_acc_reg[31:0]         <= max_acc_reg[31:0];
                        max_num[3:0]              <= max_num[3:0];
                        end
                    tr_position[6:0]              <= 7'd0;
                    tr_syn_success                <= 1'b0;                    
                    tr_syn_finish                 <= 1'b0;
                    end					
			    4'd9:
                    begin
                    tr_syn_finish                 <= 1'b1;
                    if(digital_correlate[5:0] >= 6'd0)          //����ֵ  ȡ������ֵ ��ͬ��ʼ�ճɹ�
                        begin
                        tr_position[6:3]          <= max_num[3:0];
                        tr_syn_success            <= 1'b1;
						max_test_reg[31:0]        <= max_acc_reg[31:0]; 
                       end
                   else
                       begin
                      tr_position[6:3]            <= max_num[3:0];
                      tr_syn_success              <= 1'b0;
					  max_test_reg[31:0]          <= max_acc_reg[31:0]; 
                       end                    
                    end
                endcase
                end
          
            else
                begin
                tr_position[6:0]                  <= 7'd0;
                tr_syn_finish                     <= 1'b0;
                tr_syn_success                    <= 1'b0;
                end
            end
        endcase
        end
end

//////////////////////////////////////////////////////////////////////////////////
//// debug ////
assign  debug_signal[0]                 = tr_syn_state;
assign  debug_signal[6:1]               = rx_bit_counter[5:0];
assign  debug_signal[12:7]              = rx_bit_counter[11:6];
assign  debug_signal[44:13]             = max_test_reg[31:0];//max_acc_reg[31:0];
assign  debug_signal[47:45]             = max_num[2:0]; 
assign  debug_signal[48]                = tr_syn_success;  
assign  debug_signal[49]                = tr_syn_finish;  
assign  debug_signal[65:50]             = data_in[15:0]; 
assign  debug_signal[69:66]             = tr_position[6:3]; 
assign  debug_signal[70]                = tr_syn_en;
assign  debug_signal[127:71]            = 57'd0; 




//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule 