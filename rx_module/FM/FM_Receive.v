


/*====================================================================
**�������ƣ�
			FM_Receive
**����������
			nrst	:�͵�ƽ��λ
           	sclk	:ϵͳʱ��200MHz
			
**�������ܣ�
            FM�����ܹ���
		   
**���ʱ�䣺
			2014-2-25
**������ߣ�
			CaiJinping
================================================*/

module FM_Receive(
							logic_rst_in,
							nrst,
							clk,
							I_in,
							Q_in,
							in_en,
							FM_out,
							FM_out_en,
							FM_de_bit,
							debug);

/*==========��������==========
**	N	     ����λ��
==============================*/
parameter N = 18;

/*==========�����ӿ�==========*/
input logic_rst_in;
input nrst;
input clk;
input [N-1:0] I_in,Q_in;
input in_en;
output[N-1:0] FM_out;
output FM_out_en;
output FM_de_bit;

output [255:0] debug;


/*==========wire����������==========
**	smult_result1-2		 �˷������
===================================*/
wire[N-1:0] FM_out_64;

wire[N*2-1:0] I_2, Q_2, unit_result;
wire[N-1:0] rom_unit, unit_out;
reg[N*2-1:0] I2_Q2;

reg de_bit;
// =================================================================
// ============================ FM_64 =============================
// =================================================================

/* === FM_64 === */
FM #(N,24'd5369) FM_inst1(
				.nrst(nrst),
				.sclk(clk),
				.I_in(I_in),
				.Q_in(Q_in),
				.FM_out(FM_out_64));

// =================================================================
// ================== FM:��һ�� + DEC:64 -> 21.33 + LPF==============
// =================================================================

SMULT_18X18 SMULT_18X18_inst_I2(
				.clk(clk),
				.a(I_in),
				.b(I_in),
				.p(I_2));

SMULT_18X18 SMULT_18X18_inst_Q2(
				.clk(clk),
				.a(Q_in),
				.b(Q_in),
				.p(Q_2));

always@(negedge nrst or posedge clk)
if(nrst == 1'b0) I2_Q2 <= 36'd0;
else I2_Q2 <= I_2 + Q_2;

ROM_UNIT ROM_UNIT_inst(
				.clka(clk),
				.addra(I2_Q2[35:26]), // Bus [9 : 0] 
				.douta(rom_unit)); // Bus [17 : 0] 
				
SMULT_18X18 SMULT_18X18_inst_unit(
				.clk(clk),
				.a(FM_out_64),
				.b(rom_unit),
				.p(unit_result));
				
assign unit_out = unit_result[30:13];

/* === DEC:64 -> 21.33 === */
wire [36:0]fir_dout;
wire fir_rdy;
wire [20:0]rx_fir_rnd;
wire [17:0]rx_fir_sat;
wire [20:0]rx_fir_rnd1;
wire [17:0]rx_fir_sat1;
reg rx_fir_en;
reg rx_fir_en_dl;
rx_fir_64kto21k fir_init(
  .sclr(logic_rst_in),//input sclr
  .ce(1'b1),//input ce
  .rfd(),//output rfd
  .rdy(fir_rdy),//output rdy
  .nd(in_en), //input nd
  .clk(clk),//input clk
  .dout(fir_dout[36:0]),//output [36 : 0] dout
  .din(unit_out)//input [17 : 0] din
);

rnd#
  (     
    .IN_WIDTH     ( 37 ),  //37
    .RND_WIDTH    ( 16 )   //16
 )
  u1
  (                                                   
    .clk    ( clk ),
    .rst    ( logic_rst_in  ),
    .din_i  ( fir_dout[36:0]   ),
    .din_q  ( fir_dout[36:0]   ),
                                       
    .dout_i ( rx_fir_rnd[20:0] ),
    .dout_q ( rx_fir_rnd1[20:0] )
   );


sat#
   (     
     .IN_WIDTH    ( 21 ),//19
     .SAT_WIDTH   ( 3 ) //3
   ) 
   u2
   (                                                    
     .clk   ( clk ),
     .rst   ( logic_rst_in  ),
     .din_i ( rx_fir_rnd[20:0] ),
     .din_q ( rx_fir_rnd1[20:0] ),
            
     .dout_i( rx_fir_sat[17:0] ),
     .dout_q( rx_fir_sat1[17:0] )
    );  

always@(posedge clk or posedge logic_rst_in) begin
		if(logic_rst_in) begin
				rx_fir_en 		<= 1'b0;
				rx_fir_en_dl   <= 1'b0;
		end
		else begin
				rx_fir_en_dl <= fir_rdy;
				rx_fir_en    <= rx_fir_en_dl;
		end
end

assign FM_out = rx_fir_sat;
assign FM_out_en = rx_fir_en;
assign FM_de_bit = de_bit;

//// (3) decision////
//�о�ģ�飬ͨ�������λ���о����ɽ�ģ���źţ��ع�Ϊ���ֵ����ԣ�������λΪ1�����ʱΪ����Ӧ0��
//������λΪ0�����ʱΪ������Ӧ1�����ֻ��Ҫ����λȡ���Ϳ�������о�����
always @(posedge clk)
begin
    if(logic_rst_in) begin
        de_bit               <= 1'b0;
    end                      
    else if(rx_fir_en)begin
		de_bit               <=  ~rx_fir_sat[N-1];  // �Է���λȡ������Ϊ��������
    end
end

/////////////////////////////////////////////////////////////
assign debug[17:0] = I_in[17:0];
assign debug[35:18] = Q_in[17:0];
assign debug[36] = in_en;
assign debug[54:37] = FM_out_64[17:0];
assign debug[90:55] = unit_result[35:0];
assign debug[127:91] = fir_dout[36:0];
assign debug[148:128] = rx_fir_rnd[20:0];
assign debug[166:149] = rx_fir_sat[17:0];
assign debug[167] = rx_fir_en;
assign debug[168] = FM_de_bit;


endmodule									

