/*================================================
**�������ƣ�
			FM
**����������
			nrst	:�͵�ƽ��λ
           	sclk	:ϵͳʱ��73.728MHz
			
**�������ܣ�
            FM����ܹ���
		   
**���ʱ�䣺
			2014-2-25
**������ߣ�
			CaiJinping
================================================*/

module FM(nrst,sclk,I_in,Q_in,FM_out);

/*==========��������==========
**	N	     ����λ��
**	freStep	 �˲���ʱ�ӷ�Ƶϵ��	clk = sclk*freStep/2^24
==============================*/
parameter N = 18;
parameter freStep = 24'd524288;
/*==========�����ӿ�==========*/
input nrst;
input sclk;
input[N-1:0] I_in,Q_in;
output[N-1:0] FM_out;

/*==========wire����������==========
**	smult_result1-2		 �˷������
===================================*/
wire[N*2-1:0] smult_result1,smult_result2,wire_FM;
wire clk;
//wire[N-1:0] tmp_FM;
/*==========reg����������==========
**	freCount	 ʱ�ӷ�Ƶ������
==================================*/
reg[N-1:0] delayI,delayQ,delayFM;
reg[23 :0] freCount;

/*==========�߼�������==========*/

/*===freCount ʱ�ӷ�Ƶ������===*/
always@(negedge nrst or posedge sclk)
	freCount <= (nrst == 1'b0) ? 24'd0 : freCount + freStep;

/*===clk �˲�������ʱ��===*/	
assign 	clk = freCount[23];

/*===delay===*/
always@(negedge nrst or posedge clk)
if(1'b0 == nrst) begin delayI <= 18'd0; delayQ <= 18'd0; end
else begin delayI <= I_in; delayQ <= Q_in; end

/*===mult====*/
//SMULT_18X18 SMULT_18X18_inst1(.clock(clk),.dataa(delayI),.datab(Q_in),.result(smult_result1));
//SMULT_18X18 SMULT_18X18_inst2(.clock(clk),.dataa(delayQ),.datab(I_in),.result(smult_result2));
SMULT_18X18 SMULT_18X18_inst1 (
	.clk(clk),
	.a(delayI), // Bus [17 : 0] 
	.b(Q_in), // Bus [17 : 0] 
	.p(smult_result1)); // Bus [35 : 0] 
SMULT_18X18 SMULT_18X18_inst2 (
	.clk(clk),
	.a(delayQ), // Bus [17 : 0] 
	.b(I_in), // Bus [17 : 0] 
	.p(smult_result2)); // Bus [35 : 0] 
/*===sub===*/
//SSUB_18s18 SSUB_18s18_inst(.clock(clk),.dataa(smult_result1),.datab(smult_result2),.result(wire_FM));

SSUB_18s18 SSUB_18s18_inst (
	.a(smult_result1), // Bus [35 : 0] 
	.b(smult_result2), // Bus [35 : 0] 
	.clk(clk),
	.s(wire_FM)); // Bus [35 : 0] 
	
assign FM_out = wire_FM[N*2-2:N-1];
//MovingFilter MovingFilter_inst(.nrst(nrst),.sclk(clk),.data_in(tmp_FM),.data_out(FM_out));

/*
always@(negedge nrst or posedge clk)
	FM_out <= (1'b0 == nrst) ? 18'd0 : tmp_FM;
*/
/*===filter===*/
/*
always@(negedge nrst or posedge clk)
	delayFM <= (1'b0 == nrst) ? 18'd0 : tmp_FM;

always@(negedge nrst or posedge clk)
	FM_out <= (1'b0 == nrst) ? 18'd0 : (($signed(tmp_FM) < $signed(delayFM)) ? tmp_FM : delayFM);
*/

endmodule									