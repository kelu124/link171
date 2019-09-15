`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:
// Design Name:    
// Module Name:    my_uart_top
// Project Name:   
// Target Device:  
// Tool versions:  
// Description:
//
// Dependencies:
// RS232���ܻ���8byte������������10���ֽڣ���ʼ��������ʶ�ֱ�Ϊ8'hc0��8'hcf;
// ��ģ����53--55�е���ֵ��Ҫ����ʱ�ӺͲ����ʣ������ȷ����
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// ��ӭ����EDN��FPGA/CPLD��ѧС��һ�����ۣ�http://group.ednchina.com/1375/
////////////////////////////////////////////////////////////////////////////////
module uart_top(
				clk,rst_n,
				rs232_rx,
				rs232_tx,
				recieve_data,recirve_vld,
				send_en,send_data,send_vld,
				debug_signal
				);

input clk;			// 50MHz��ʱ��
input rst_n;		//�͵�ƽ��λ�ź�

input rs232_rx;		// RS232���������ź�
output rs232_tx;	//	RS232���������ź�

output [63:0] recieve_data;		//���������Ľ�������
output recirve_vld;				//�������ָʾ��Ϊ�߱�ʾ���ܵ�һ��64λ����

input send_en;					//��������ָʾ��Ϊ�����弴����һ��64λ���������
input [63:0] send_data;			//���������Ľ�������
output send_vld;				//�������������Ϊ�ߣ�send_en����send_vldΪ��ʱ��Ч
output [255:0] debug_signal;  //debug�ź�

wire bps_start1,bps_start2;	//���յ����ݺ󣬲�����ʱ�������ź���λ
wire clk_bps1,clk_bps2;		// clk_bps_r�ߵ�ƽΪ��������λ���м������,ͬʱҲ��Ϊ�������ݵ����ݸı�� 
wire[7:0] rx_data;	//�������ݼĴ���������ֱ����һ����������
wire rx_int;		//���������ж��ź�,���յ������ڼ�ʼ��Ϊ�ߵ�ƽ
wire comnd_en;		//�ⲿ����ʹ�ܷ���ģ��
wire [7:0] comnd_data;
wire send_en_valid;	//�ڲ�����ʱ��Ϊ��

parameter		BPS_PARA 	=	172,		//�����ʷ�Ƶ����ֵ = ��ϵͳʱ��clk / �����ʣ�-1
				BPS_PARA_2	=	86,		//Ϊ�����ʷ�Ƶ����ֵ��һ�룬�������ݲ���
				WAIT_TIME	=	1910;	//WAIT_TIME == clk / ������ * 11

wire       rs232_tx_intel;  //FPGA�ڲ�������ź�   
                
//�л��������ߵ�������ڽ����ֽڹ�����ʱ��ֱ�Ӷ̽�tx = rx_data
assign     rs232_tx     =    bps_start1 ? rs232_rx : rs232_tx_intel;
                
//----------------------------------------------------
//������ĸ�ģ���У�speed_rx��speed_tx��������ȫ������Ӳ��ģ�飬�ɳ�֮Ϊ�߼�����
//��������Դ����������е�ͬһ���ӳ�����ò��ܻ�Ϊһ̸��
////////////////////////////////////////////
speed_select	#(.BPS_PARA(BPS_PARA),
				  .BPS_PARA_2(BPS_PARA_2))	
				speed_rx(	
							.clk(clk),	//������ѡ��ģ��
							.rst_n(rst_n),
							.bps_start(bps_start1),
							.clk_bps(clk_bps1)
						);

my_uart_rx			my_uart_rx(		
							.clk(clk),	//��������ģ��
							.rst_n(rst_n),
							.rs232_rx(rs232_rx),		//rs232_rx
							.rx_data(rx_data),
							.rx_int(rx_int),
							.clk_bps(clk_bps1),
							.bps_start(bps_start1)
						);

///////////////////////////////////////////						
speed_select	#(.BPS_PARA(BPS_PARA),
				  .BPS_PARA_2(BPS_PARA_2))	
			  speed_tx(	
							.clk(clk),	//������ѡ��ģ��
							.rst_n(rst_n),
							.bps_start(bps_start2),
							.clk_bps(clk_bps2)
						);

my_uart_tx			my_uart_tx(		
							.clk(clk),	//��������ģ��
							.rst_n(rst_n),
							.rx_data(rx_data),
							.rx_int(rx_int),
							.rs232_tx(rs232_tx_intel), //rs232_tx
							.clk_bps(clk_bps2),
							.bps_start(bps_start2),
							.comnd_en(comnd_en),
							.send_en_valid(send_en_valid),
							.comnd_data(comnd_data)
						);
//�������
rx_decode	#(.WAIT_TIME(WAIT_TIME))		
            rx_decode_u(
							.clk(clk),	//��������ģ��
							.rst_n(rst_n),
							.rx_ready(bps_start1),	//Ϊ��ʱ��ʾ���ڽ���״̬��Ϊ�ͲŽ����µĽ���
							.rx_data(rx_data),
							.recieve_data(recieve_data),
							.recirve_vld(recirve_vld)
						);
//�������
tx_decode			tx_decode_u(
							.clk(clk),	//��������ģ��
							.rst_n(rst_n),
							.tx_ready(bps_start2),	//Ϊ��ʱ��ʾ���ڽ���״̬��Ϊ�ͲŽ����µĽ���,input
							.send_en(send_en),  //input
							.send_en_valid(send_en_valid),
							.tx_data(send_data),  //input
							.comnd_data(comnd_data),
							.send_vld(send_vld),
							.comnd_en(comnd_en)
						);


//////////////////////////////////////////////////////////////////////////////////////////////
assign debug_signal[0] = rs232_rx;
assign debug_signal[1] = rs232_tx;
assign debug_signal[2] = recirve_vld;
assign debug_signal[3] = send_en;
assign debug_signal[4] = send_vld;
assign debug_signal[68:5] = recieve_data[63:0];
assign debug_signal[132:69] = send_data[63:0];

endmodule
