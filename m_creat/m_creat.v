module m_creat
(
sys_clk,
sys_rst_n,
out,shift
);
//input
input sys_clk;
input sys_rst_n;

//output
output out;//�������
output [ 31:0 ]shift;//4λ��λ�Ĵ���ֵ�����
reg [ 3:0 ]rShift;//4λ��λ�Ĵ���
reg rOut;

/************************************************************************/
wire feedback = rShift[ 0 ]^rShift[ 3 ];
assign out= rOut;
assign shift[31:0] = {rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0],rShift[3:0]};

/***********************************************************************/
always @( posedge sys_clk or negedge sys_rst_n )
if( sys_rst_n == 0 )begin //��ʼ��
rShift <= 4'b0110;
rOut <= 1'b0;
end
else
begin
rShift <= { feedback,rShift[ 3:1 ] }; //��λ����
rOut <= rShift[ 0 ];
end
endmodule
