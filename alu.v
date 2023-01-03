`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu(
    input wire clk, rst,
    input wire flushE,
    input wire [31:0] src_aE, src_bE,  //������
    input wire [4:0] alucontrolE,  //alu �����ź�
    input wire [4:0] sa, //saֵ
    input wire [63:0] hilo,  //hiloֵ

    output wire div_stallE,
    output wire [63:0] aluoutE, //alu���
    output wire overflowE//�������
);
    wire [63:0] aluout_div; //�˳������
    reg [63:0] aluout_mul;
    wire mul_sign; //�˷�����
    wire mul_valid;  // Ϊ�˷�
    wire div_sign; //��������
	wire div_vaild;  //Ϊ����
	wire ready;
    reg [31:0] aluout_simple; // ��ͨ������
    reg carry_bit;  //��λ �ж����


    //�˷��ź�
	assign mul_sign = (alucontrolE == `MULT_CONTROL);
    assign mul_valid = (alucontrolE == `MULT_CONTROL) | (alucontrolE == `MULTU_CONTROL);

    //aluout
    assign aluoutE = ({64{div_vaild}} & aluout_div)
                    | ({64{mul_valid}} & aluout_mul)
                    | ({64{~mul_valid & ~div_vaild}} & {32'b0, aluout_simple})
                    | ({64{(alucontrolE == `MTHI_CONTROL)}} & {src_aE, hilo[31:0]}) // ��Ϊmthi/mtlo ֱ��ȡHilo�ĵ�32λ�͸�32λ
                    | ({64{(alucontrolE == `MTLO_CONTROL)}} & {hilo[63:32], src_aE});
    // Ϊ�Ӽ� �����λ�����λ����ʱ �������
    assign overflowE = (alucontrolE==`ADD_CONTROL || alucontrolE==`SUB_CONTROL) & (carry_bit ^ aluout_simple[31]);

    // ������������Ӧ����
    always @(*) begin
        carry_bit = 0; //���λȡ0
        case(alucontrolE)
            `AND_CONTROL:       aluout_simple = src_aE & src_bE;
            `OR_CONTROL:        aluout_simple = src_aE | src_bE;
            `NOR_CONTROL:       aluout_simple =~(src_aE | src_bE);
            `XOR_CONTROL:       aluout_simple = src_aE ^ src_bE;

            `ADD_CONTROL:       {carry_bit, aluout_simple} = {src_aE[31], src_aE} + {src_bE[31], src_bE};
            `ADDU_CONTROL:      aluout_simple = src_aE + src_bE;
            `SUB_CONTROL:       {carry_bit, aluout_simple} = {src_aE[31], src_aE} - {src_bE[31], src_bE};
            `SUBU_CONTROL:      aluout_simple = src_aE - src_bE;

            `SLT_CONTROL:       aluout_simple = $signed(src_aE) < $signed(src_bE); //�з��űȽ�
            `SLTU_CONTROL:      aluout_simple = src_aE < src_bE; //�޷��űȽ�

            `SLLV_CONTROL:       aluout_simple = src_bE << src_aE[4:0]; //��λsrc a
            `SRLV_CONTROL:       aluout_simple = src_bE >> src_aE[4:0];
            `SRAV_CONTROL:       aluout_simple = $signed(src_bE) >>> src_aE[4:0];

            `SLL_CONTROL:    aluout_simple = src_bE << sa; //��λsa
            `SRL_CONTROL:    aluout_simple = src_bE >> sa;
            `SRA_CONTROL:    aluout_simple = $signed(src_bE) >>> sa;

            `LUI_CONTROL:       aluout_simple = {src_bE[15:0], 16'b0}; //ȡ��16λ
            5'b00000: aluout_simple = src_aE;  // do nothing

            default:    aluout_simple = 32'b0;
        endcase
    end
	mul mul(src_aE,src_bE,mul_sign,aluout_mul);

    // ����
	assign div_sign = (alucontrolE == `DIV_CONTROL);
	assign div_vaild = (alucontrolE == `DIV_CONTROL || alucontrolE == `DIVU_CONTROL);

	div div(
		.clk(~clk),
		.rst(rst),
        .flush(flushE),
		.a(src_aE),  //divident
		.b(src_bE),  //divisor
		.valid(div_vaild),
		.sign(div_sign),   //1 signed

		// .ready(ready),
		.div_stall(div_stallE),
		.result(aluout_div)
	);

endmodule
