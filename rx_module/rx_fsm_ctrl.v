//////////////////////////////////////////////////////////////////////////////////
// Company:         StarPoint
// Engineer:        GUO YAN 
// 
// Create Date:     16:17:12 07/27/2015 
// Module Name:     rx_fsm_ctrl 
// Project Name:    Rx synchronization correlation process;
// Target Devices:  FPGA - XC7K325T - FFG900; 
// Tool versions:   ISE14.6;   
// Description:
//                  
//
// Revision:        v1.0 - File Created
// Additional Comments: 
// 1. 
// 2.
// 3. 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module rx_fsm_ctrl(
//// clock/reset ////
input               logic_clk_in,               // 200MHz logic clock
input               logic_rst_in, 

//sync signals
input               coarse_syn_success,
input[4:0]          coarse_position,		   //���ֵһֱ�ڱ䣬���ֻ�������ڴ�ͬ��״̬�ɹ�֮����ֵ���룬����ʱ�̾������á��ʽ����ֵ�ĸ�ֵ���ڴ�ͬ����⵽��ͬ���ɹ���λ��

input               tr_syn_finish,
input               tr_syn_success,
input[6:0]          tr_position,

//input data 
input               de_bit_in,
input[8:0]          rx_slot_length,

//output syn signals
output              tr_syn_en_out,              // ������ͬ����ʹ���ź�
output              coarse_flag_out,           // ����ָʾ��ͬ��״̬
output              tr_flag_out,               // ����ָʾ��ͬ��״̬

//output hop frequence signals
//output              time_slot_data_en,         // 1: ����Ϊ��ǰʱ϶�����ݶ�   0�� ����Ϊ��ǰʱ϶��ͬ����
output[9:0]         rx_freq_ram_addr_out,        // ������Ƶ�ʱ��ַ�ź�
output              rx_freq_ram_rd_out,
input [9:0]         rx_freq_pn_addr_ini_in,     //ul freq and pn ram pattern initial addr
input               rx_freq_pn_ini_en_in,       //ul freq and pn ram pattern initial addr update enable

//output hop frequence signals
output              rx_data_valid_out,         // ����ʹ���ź�
output[31:0]        rx_data_out,               // ���32-bit���ݵ��������

output[199:0]       debug_signal
);
//////////////////////////////////////////////////////////////////////////////////
//// signals declaration ////
reg [8:0]            rx_fh_counter            = 9'd0;      // ��Ƶ��������
reg [11:0]           rx_fh_period_counter     = 12'd0;     // ��������Ϊһ����Ƶ����
reg [6:0]            tr_position_reg          = 7'd0;
       		                                  
reg [1:0]            rx_fh_ctrl_state;  
//wire[31:0]         coarse_cal_cnt_out;      
reg [31:0]           coarse_delay_count       = 32'd0;
reg [31:0]           tr_delay_count           = 32'd0;
reg [31:0]           delay_counter_1          = 32'd0;
reg [31:0]           delay_counter_2          = 32'd0;


reg [9:0]            rx_freq_ram_addr         = 10'd32;
reg                  rx_freq_ram_rd           = 1'b0;
                                              
reg                  rx_data_valid            = 1'b0;
reg [31:0]           rx_data                  = 32'd0;
wire[12:0]           bit_counter; 

reg                  coarse_freq_dly_en       = 1'b0;
reg[15:0]            coarse_freq_dly_cnt      = 16'd0;
reg                  coarse_freq_dly_pulse    = 1'b0;  

reg                  rx_13us_start            = 1'b0;                  
reg[15:0]            rx_13us_cnt              = 16'd0;

reg                  tr_syn_en                = 1'b0;  
reg                  coarse_flag              = 1'b0;
reg                  tr_flag                  = 1'b0;    

//////////////////////////////////////////////////////////////////////////////////
//// parameter defination ////
parameter            syn_code_num             = 8'd40;         //ͬ�������������40��ͬ�����壨32����ͬ��+8����ͬ�����壩
parameter            tr_code_position         = 9'd32;         //trλ��
parameter            data_position            = 9'd40;         //����λ��
parameter            rx_13us_length           = 16'd2599;      //13us����һ��Ƶ�ʿ����� // 200M*13us=2600
parameter            rx_6_4us_length          = 13'd1279;      //13us����һ��Ƶ�ʿ����� // 200M*6.4us=1280
                                              
parameter            rx_freq_upd_delay        = 16'd98;        //freq update after coarse_sucess 100clk


//parameter            tr_position_length    = 24'd41599;   //tr����λ��clk�� 32pulse*65bit*20clk(10ns)=41600; 13us*32pulse/10ns=41600
//parameter            data_position_length  = 24'd51999;      //����λ��clk��   40pulse*65bit*20clk(10ns)=52000; 13us*40pulse/10ns=52000


// ����⵽��ͬ��ͷ����Ҫ��ʱ��ʱ����������
//parameter   coarse_delay_count          = (((tr_code_position - coarse_position - 1)*65 + 33)*40 - 18 - 20);	//delay counter
// -1  : coarse_position��0��ʼ������tr_code_position��1~32������32��pulse
// 65  : ÿ�����ݶ�Ӧ65bit; 13us/200ns=65
// 40  : ����200MHz����ʱ�ӣ�ÿ����Ԫ(1��bit)ռ200/5=40��ʱ��
// 33  : ��ͬ�����������6.6us��ʱ��(33bit)
// 18  : �ӵ�4����ͬ����ʵ�����������������ͬ���ź���Ҫ10��clk�ӳ�
// 20  : ����ͬ�������Ķ�ʱʱ����ǰ�����Ԫ�������Դ�ͬ����ʱʱ��Ϊ����ǰ��������Ԫ����Ѳ���ʱ�̣���֤�������ط壬��֤tr_syn_en����tr�ź�
// ���۴�ͬ���Ĵ����������Ϊ5M����25M��һ�������13us�ǹ̶���


// ����ɾ�ͨͬ��ͷ�󣬵�����������Ҫ��ʱ��ʱ����������ע������Ҫ���ǽ���ͬ������ʱ����
//parameter tr_delay_count                =(((data_position - tr_code_position -1 ) * 65 + 32 - 4) * 40 - 38); 	
// -1  : ��ͬ�������ռ��һ��pulse
// 65  : ÿ�����ݶ�Ӧ65bit; 
// 32  : ��������bit��, 
// 4   : ��DDC��NCO��ǰ4����Ԫʱ��׼���á����ǿ���ȥ��(����)����ΪNCO��ֵ����ͨ��coarse_success�����ļ���������Ϊ��ͬ����֤�����һ����Ԫ��
// 38  : trͬ����5��������ѡ����Ѳ������ӳ�38clk
// 40  : ����200MHz����ʱ�ӣ�ÿ����Ԫ(1��bit)ռ200/5=40��ʱ��


//////////////////////////////////////////////////////////////////////////////////
//// (0) signal assigment ////
// ����time_slot_data_en�źţ�1: ��ǰ����ʱ϶�����ݶΣ� 0����ǰ����ʱ϶��ͬ���Σ�ʵ�ʲ��Խ׶�ΪFPGA���ݽ���ģ����������ݡ�
 //assign   time_slot_data_en             = (( rx_fh_ctrl_state == 2'd2 ) && (delay_counter_2[31:0] == tr_delay_count + tr_position_reg)) ? 1'b1 : 1'b0;
                                        
 assign   rx_data_valid_out             = rx_data_valid;
 assign   rx_data_out[31:0]             = rx_data[31:0];
                                        
 assign   rx_freq_ram_addr_out[9:0]     = rx_freq_ram_addr[9:0];
 assign   rx_freq_ram_rd_out            = rx_freq_ram_rd;    

 assign   tr_syn_en_out                 = tr_syn_en;    
 assign   coarse_flag_out               = coarse_flag;
 assign   tr_flag_out                   = tr_flag;    
//////////////////////////////////////////////////////////////////////////////////
//// (1)keep tr position 
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        tr_position_reg[6:0]                <= 7'd0;
    else                                    
        begin                               
        if(tr_syn_success)                  
			begin                           
				tr_position_reg[6:0]        <= tr_position[6:0];
			end                             
		else                                
            tr_position_reg[6:0]            <= tr_position_reg[6:0];
        end
end


//////////////////////////////////////////////////////////////////////////////////
//// (2) FSM 
always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin
        rx_fh_counter[8:0]                          <= 9'd0;
        rx_fh_period_counter[11:0]                  <= 12'd0;
        rx_fh_ctrl_state                            <= 2'd0;
        delay_counter_1[31:0]                       <= 32'd0;
        delay_counter_2[31:0]                       <= 32'd0;
        tr_syn_en                                   <= 1'b0;
		coarse_flag                                 <= 1'b0;
		tr_flag                                     <= 1'b0;
        end
    else
        begin
        case(rx_fh_ctrl_state)
        2'd0:  // ��ͬ��״̬
            begin
            rx_fh_counter[8:0]                      <= 9'd0;
            rx_fh_period_counter[11:0]              <= 12'd0;
            delay_counter_1[31:0]                   <= 32'd0;
            delay_counter_2[31:0]                   <= 32'd0;
            tr_syn_en                               <= 1'b0;
            if(coarse_syn_success == 1'b1)// ��ͬ���ɹ�
                begin
					rx_fh_ctrl_state                <= 2'd1; // ת�뾫ͬ��״̬
					coarse_delay_count[31:0]        <= 32'd1282;//(((tr_code_position - coarse_position[4:0] - 1)*65 + 33)*40 - 18 - 20);	
				end                                 
			else                                    
                rx_fh_ctrl_state                    <= 2'd0;
            end                                     
                                                    
        2'd1:  // ��ͬ��״̬                        
            begin                                   
            if(delay_counter_1[31:0] <= coarse_delay_count[31:0]) //delay_counter_1���ڴ�ͬ���ɹ��󣬰�����ͬ���ҵ���ʼλ��
                delay_counter_1[31:0]               <= delay_counter_1[31:0] + 1'b1;
            else
                delay_counter_1[31:0]               <= delay_counter_1[31:0]; 
                
            if(delay_counter_1[31:0] == coarse_delay_count[31:0] )
				begin
					tr_syn_en                       <= 1'b1;
					coarse_flag                     <= ~coarse_flag; 
				end                                 
			else                                    
                tr_syn_en                           <= 1'b0;
				
			       
            if(tr_syn_finish == 1'b1)
                begin
                if(tr_syn_success == 1'b1)
                    begin
					tr_flag                         <= ~tr_flag; 
					tr_delay_count[31:0]            <= 32'd19282;//(((data_position - tr_code_position -1 ) * 65 + 32 - 4) * 40 - 38); 
                    rx_fh_ctrl_state                <= 2'd2;   // ��ͬ���ɹ�����ת�����ݽ���״̬
                    end                             
                else                                
                    begin                           
                    rx_fh_ctrl_state                <= 2'd0;   // ��ͬ��ʧ�ܣ������»ص���ͬ��״̬
                    end                             
                end                                 
            else                                    
                rx_fh_ctrl_state                    <= 2'd1;
            end                                     
                                                    
        2'd2:  // ��������״̬                      
            begin                                       
            if(delay_counter_2[31:0] == (tr_delay_count[31:0] + tr_position_reg[6:0]))     // ���ӳ�tr_delay_count����������������rx_fh_counter��                                                                        
		    begin                                                            // rx_fh_period_counter�����ƽ������ݵ�Ƶ���л������ݽ���
                delay_counter_2[31:0]               <= delay_counter_2[31:0];  				
               // if(rx_fh_counter[8:0] >= (rx_slot_length[8:0] - syn_code_num + 9'd12) ) // ���ݲ�����Ƶ�������,������12���Ľ���ʱ�䣬��֤����ļĴ����ܹ���ȷд���ٿ�ʼ��ȡ
			    if(rx_fh_counter[8:0] >= (rx_slot_length[8:0] - syn_code_num ) ) //ÿһ��(�ķ�1.6us)��6.6us����ʱ���ڿ���ɣ����Ӻ�ʹ��rx_buffer��wr���ƶ�12
                    begin                       				
                    rx_fh_period_counter[11:0]      <= 12'd0;
                    rx_fh_counter[8:0]              <= 9'd0;
                    rx_fh_ctrl_state                <= 1'b0;  //�趨��fh_num - syn_code_num,������һ��ʱ϶�����ݺ󣬻ص�״̬���ĳ�ʼ״̬				
				   end
                else  //(1)
                    begin
                    if(rx_fh_period_counter[11:0] == rx_13us_length)//13us����һ��Ƶ�ʿ����� // 200M*13us=2600
                        begin
                        rx_fh_period_counter[11:0]  <= 12'd0;  
                        rx_fh_counter[8:0]          <= rx_fh_counter[8:0] + 1'b1; 						
                        end
                    else //(2)
                        begin
						rx_fh_period_counter[11:0]  <= rx_fh_period_counter[11:0] + 1'b1;
						rx_fh_counter[8:0]          <= rx_fh_counter[8:0];
                        end //end else(2)
						
                    rx_fh_ctrl_state                           <= 2'd2;
                    end //end else(1)
                end //end if(delay_counter_2 == tr_delay_count + tr_position_reg)  
           else
                begin
                delay_counter_2[31:0]                          <= delay_counter_2[31:0] + 1'b1;
                rx_fh_counter[8:0]                             <= 9'd0;
                rx_fh_period_counter[11:0]                     <= 12'd0;
                rx_fh_ctrl_state                               <= 2'd2;
                end                                            
            tr_syn_en                                          <= 1'b0;
            end                                          
        default:                                         
            begin                                        
            rx_fh_counter[8:0]                                 <= 9'd0;
            rx_fh_period_counter[11:0]                         <= 12'd0;
            rx_fh_ctrl_state                                   <= 2'd0;
            delay_counter_1[31:0]                              <= 32'd0;
            delay_counter_2[31:0]                              <= 32'd0;
            tr_syn_en                                          <= 1'b0;
            end
        endcase
        end

end

//////////////////////////////////////////////////////////////////////////////////
//// (3)������ƵƵ�ʲ���ģ��
//(3-0)freq/pn update start after coarse_sucess 100clk
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        coarse_freq_dly_en                <= 1'b0;
    end 
    else if(coarse_freq_dly_cnt[15:0] == rx_freq_upd_delay)    begin
	    coarse_freq_dly_en                <= 1'b0;	   
    end	
	else if(coarse_syn_success == 1'b1) begin    
	    coarse_freq_dly_en                <= 1'b1;	
    end                              
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        coarse_freq_dly_cnt[15:0]         <= 16'd0;
    end 
    else if(coarse_freq_dly_cnt[15:0] == rx_freq_upd_delay)   begin 
	   coarse_freq_dly_cnt[15:0]          <= 16'd0;   
    end	
	else if(coarse_freq_dly_en) begin             
	    coarse_freq_dly_cnt[15:0]         <= coarse_freq_dly_cnt[15:0] + 1'b1;	
    end                              
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        coarse_freq_dly_pulse             <= 1'b0;
    end 
    else if(coarse_freq_dly_cnt[15:0] == rx_freq_upd_delay)   begin 
	    coarse_freq_dly_pulse             <= 1'b1;	   
    end	
	else  begin    
	    coarse_freq_dly_pulse             <= 1'b0;	
    end                              
end

//(3-1)13us update control
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        rx_13us_start                     <= 1'b0;
    end 
    else if((rx_fh_counter[8:0] == (rx_slot_length[8:0] - syn_code_num - 1'b1)) && (rx_13us_cnt[15:0] == rx_13us_length))   begin //�ڽ������һ������ǰֹͣ(-1)
	    rx_13us_start                     <= 1'b0;	   
    end	
	//else if(coarse_syn_success == 1'b1) begin  
    else if(coarse_freq_dly_pulse == 1'b1) begin 	
	    rx_13us_start                     <= 1'b1;	//rx_13us is ahead real 13us, �����ͬ���ɹ�Ϊֹ��6.6�����в���
    end                              
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        rx_13us_cnt[15:0]                 <= 16'd0;
    end 
    else if(rx_13us_cnt[15:0] == rx_13us_length)   begin 
	   rx_13us_cnt[15:0]                  <= 16'd0;   
    end	
	else if(rx_13us_start) begin                  
	    rx_13us_cnt[15:0]                 <= rx_13us_cnt[15:0] + 1'b1;	
    end                              
end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin
        rx_freq_ram_rd                    <= 1'b0;
    end 
    else if(rx_13us_cnt[15:0] == rx_13us_length)   begin 
	   rx_freq_ram_rd                     <= 1'b1;   
    end	
	else begin                  
	   rx_freq_ram_rd                     <= 1'b0;
    end                              
end

//(3-2)freq/pn ping-pang ram
always @(posedge logic_clk_in)
begin
    if(logic_rst_in) begin  //makesure power reset intial
        rx_freq_ram_addr[9:0]             <= 10'd32;
    end 
	else if(rx_freq_pn_ini_en_in) begin
	    rx_freq_ram_addr[9:0]             <= rx_freq_pn_addr_ini_in[9:0]; //prevent ping-pang error when unsync
	end
	else if(rx_freq_ram_rd && (rx_freq_ram_addr[9:0] == {1'b0,(rx_slot_length[8:0] - 1'b1)})) begin //4~443(71)
	    rx_freq_ram_addr[9:0]             <= 10'd544; //ping-pang ram
	end
	else if(rx_freq_ram_rd && (rx_freq_ram_addr[9:0] == (rx_slot_length[8:0] + 9'd511))) begin //516~955(587)
	    rx_freq_ram_addr[9:0]             <= 10'd32; 	//no.0~31 for coarse syn in other process
    end
	else if(rx_freq_ram_rd)begin
	    rx_freq_ram_addr[9:0]             <= rx_freq_ram_addr[9:0] + 1'b1;
    end		
end


//////////////////////////////////////////////////////////////////////////////////
//// (4)output freq ctl and rx data 
assign  bit_counter[12:0] = rx_fh_period_counter[11:0] - 12'd160;  //���ݺ�rx_fh_period_counter[11:0]����//һ����Ƶ����13us��ʼrx_fh_period_counter��������ǰ4��bit������Ƶ������, 4*200/5=160

always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin
        rx_data_valid                     <= 1'b0;
        end
    else
        begin
        if(rx_fh_period_counter[11:0] == 12'd1440)  //������32-bit����(1280+160=1440)�����bit_counter����������������Ч�ź�
            rx_data_valid                 <= 1'b1;
        else                              
            rx_data_valid                 <= 1'b0;
        end
end

////(4-1)����32-bit���ݣ�����rx_data�Ĵ�����
// always @(posedge logic_clk_in)
// begin
    // if(logic_rst_in)
        // begin
        // rx_data[31:0]                     <= 32'd0;
        // end
    // else
        // begin          
        // if((bit_counter[12:0] >= 13'd0) && (bit_counter[12:0] <= rx_6_4us_length))  
            // begin
            // case(bit_counter[12:0])        //LSB first at tx module
            // 13'd0:      rx_data[0]        <= de_bit_in;  //1bit=200ns=200ns*200MZ=40clk
            // 13'd40:     rx_data[1]        <= de_bit_in;
            // 13'd80:     rx_data[2]        <= de_bit_in;  
            // 13'd120:    rx_data[3]        <= de_bit_in;
            // 13'd160:    rx_data[4]        <= de_bit_in;
            // 13'd200:    rx_data[5]        <= de_bit_in;  
            // 13'd240:    rx_data[6]        <= de_bit_in;
            // 13'd280:    rx_data[7]        <= de_bit_in;
            // 13'd320:    rx_data[8]        <= de_bit_in;  
            // 13'd360:    rx_data[9]        <= de_bit_in;
            // 13'd400:    rx_data[10]       <= de_bit_in;
            // 13'd440:    rx_data[11]       <= de_bit_in;  
            // 13'd480:    rx_data[12]       <= de_bit_in;
            // 13'd520:    rx_data[13]       <= de_bit_in;
            // 13'd560:    rx_data[14]       <= de_bit_in;  
            // 13'd600:    rx_data[15]       <= de_bit_in;
            // 13'd640:    rx_data[16]       <= de_bit_in;
            // 13'd680:    rx_data[17]       <= de_bit_in;  
            // 13'd720:    rx_data[18]       <= de_bit_in;
            // 13'd760:    rx_data[19]       <= de_bit_in;
            // 13'd800:    rx_data[20]       <= de_bit_in; 
            // 13'd840:    rx_data[21]       <= de_bit_in;  
            // 13'd880:    rx_data[22]       <= de_bit_in;
            // 13'd920:    rx_data[23]       <= de_bit_in;
            // 13'd960:    rx_data[24]       <= de_bit_in;  
            // 13'd1000:   rx_data[25]       <= de_bit_in;
            // 13'd1040:   rx_data[26]       <= de_bit_in;
            // 13'd1080:   rx_data[27]       <= de_bit_in;  
            // 13'd1120:   rx_data[28]       <= de_bit_in;
            // 13'd1160:   rx_data[29]       <= de_bit_in;
            // 13'd1200:   rx_data[30]       <= de_bit_in; 
            // 13'd1240:   rx_data[31]       <= de_bit_in;  
            // default:    rx_data[31:0]     <= rx_data[31:0];
            // endcase
            // end
        // else
            // rx_data[31:0]                 <= rx_data[31:0];
        // end
// end

always @(posedge logic_clk_in)
begin
    if(logic_rst_in)
        begin
        rx_data[31:0]                     <= 32'd0;
        end
    else
        begin          
        if((bit_counter[12:0] >= 13'd0) && (bit_counter[12:0] <= rx_6_4us_length))  
            begin
            case(bit_counter[12:0])        //MSB first at tx module
            13'd0:      rx_data[31]       <= de_bit_in;  //1bit=200ns=200ns*200MZ=40clk
            13'd40:     rx_data[30]       <= de_bit_in;
            13'd80:     rx_data[29]       <= de_bit_in;  
            13'd120:    rx_data[28]       <= de_bit_in;
            13'd160:    rx_data[27]       <= de_bit_in;
            13'd200:    rx_data[26]       <= de_bit_in;  
            13'd240:    rx_data[25]       <= de_bit_in;
            13'd280:    rx_data[24]       <= de_bit_in;
            13'd320:    rx_data[23]       <= de_bit_in;  
            13'd360:    rx_data[22]       <= de_bit_in;
            13'd400:    rx_data[21]       <= de_bit_in;
            13'd440:    rx_data[20]       <= de_bit_in;  
            13'd480:    rx_data[19]       <= de_bit_in;
            13'd520:    rx_data[18]       <= de_bit_in;
            13'd560:    rx_data[17]       <= de_bit_in;  
            13'd600:    rx_data[16]       <= de_bit_in;
            13'd640:    rx_data[15]       <= de_bit_in;
            13'd680:    rx_data[14]       <= de_bit_in;  
            13'd720:    rx_data[13]       <= de_bit_in;
            13'd760:    rx_data[12]       <= de_bit_in;
            13'd800:    rx_data[11]       <= de_bit_in; 
            13'd840:    rx_data[10]       <= de_bit_in;  
            13'd880:    rx_data[9]        <= de_bit_in;
            13'd920:    rx_data[8]        <= de_bit_in;
            13'd960:    rx_data[7]        <= de_bit_in;  
            13'd1000:   rx_data[6]        <= de_bit_in;
            13'd1040:   rx_data[5]        <= de_bit_in;
            13'd1080:   rx_data[4]        <= de_bit_in;  
            13'd1120:   rx_data[3]        <= de_bit_in;
            13'd1160:   rx_data[2]        <= de_bit_in;
            13'd1200:   rx_data[1]        <= de_bit_in; 
            13'd1240:   rx_data[0]        <= de_bit_in;  
            default:    rx_data[31:0]     <= rx_data[31:0];
            endcase
            end
        else
            rx_data[31:0]                 <= rx_data[31:0];
        end
end

//////////////////////////////////////////////////////////////////////////////////
////(5) debug ////
assign  debug_signal[0]                  = de_bit_in;
assign  debug_signal[2:1]                = rx_fh_ctrl_state[1:0];
assign  debug_signal[3]                  = coarse_syn_success;
assign  debug_signal[4]                  = tr_syn_en;
//assign  debug_signal[5]                  = tr_syn_success;
assign  debug_signal[11:5]               = tr_position_reg[6:0];
assign  debug_signal[16:12]              = 5'd0;

assign  debug_signal[28:17]              = rx_fh_period_counter[11:0];
assign  debug_signal[37:29]              = rx_fh_counter[8:0]; 
assign  debug_signal[38]                 = tr_syn_success;//rx_13us_start;
assign  debug_signal[48:39]              = rx_freq_ram_addr[9:0];
assign  debug_signal[61:49]              = bit_counter[12:0];
assign  debug_signal[62]                 = rx_data_valid;
assign  debug_signal[94:63]              = rx_data[31:0]; 

assign  debug_signal[95]                 = coarse_flag;
assign  debug_signal[96]                 = tr_flag;


                 
// assign  debug_signal[128:97]             = delay_counter_2[31:0];//coarse_delay_count[31:0]; 
// assign  debug_signal[160:129]            = delay_counter_1[31:0]; 
// assign  debug_signal[192:161]            = tr_delay_count[31:0];
// assign  debug_signal[193]                = rx_13us_start;//tr_syn_success;
//assign  debug_signal[199:194]            = 6'd0;

assign  debug_signal[199:97]            = 103'd0;



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

endmodule
