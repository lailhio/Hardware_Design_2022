`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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
`include "defines2.vh"

module maindec(
	input wire[31:0] instrD,

	input wire stallE, stallM, stallW,
	input wire flushE, flushM, flushW,
    //ID
    output wire sign_exD,          //�������Ƿ�Ϊ������չ
    //EX
    output reg [1:0] reg_dstE,     	//д�Ĵ���ѡ��  00-> rd, 01-> rt, 10-> д$ra
    output reg is_immE,        //alu srcbѡ�� 0->rd2E, 1->immE
    output reg reg_write_enE,
	output reg hilo_wenE,
	//MEM
	output reg mem_readM, mem_writeM,
	output reg reg_write_enM,		//д�Ĵ�����ʹ��
    output reg mem_to_regM,         //resultѡ�� 0->alu_out, 1->read_data
	output reg hilo_to_regM,			// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	output reg riM,
	output reg breakM, syscallM, eretM, 
	output reg cp0_wenM,
	output reg cp0_to_regM
    //WB
    );
	//Declare
	wire [1:0] reg_dstD;
    wire is_immD, reg_write_enD, mem_to_regD, mem_readD, mem_writeD;

    reg mem_to_regE, mem_readE, mem_writeE;

	wire hilo_wenD, cp0_wenD;
	reg cp0_wenE;
	wire hilo_to_regD, cp0_to_regD;
	reg hilo_to_regE, cp0_to_regE;

	reg riD, riE;
	//����ָ��
	wire 	breakD, syscallD;
	reg 	breakE, syscallE;
	//�жϷ���
	wire 	eretD;
	reg 	eretE;

	//Instruct Divide
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD,rdD;
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];

	//һ�����ܹ������жϵ��ź�
	assign sign_exD = (|(opD[5:2] ^ 4'b0011));		//0��ʾ�޷�����չ��1��ʾ�з���
	assign hilo_wenD = ~(|( opD^ `R_TYPE )) 		//�����ж��ǲ���R-type
						& (~(|(functD[5:2] ^ 4'b0110)) 			// div divu mult multu 	
							|( ~(|(functD[5:2] ^ 4'b0100)) & functD[0]) //mthi mtlo
						  );
	assign hilo_to_regD = ~(|(opD ^ `R_TYPE)) & (~(|(functD[5:2] ^ 4'b0100)) & ~functD[0]);
														// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	assign cp0_wenD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rs ^ `MFC0));
	assign cp0_to_regD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rs ^ `MTC0));
	assign eretD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rs ^ `ERET));
	
	assign breakD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `BREAK));
	assign syscallD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `SYSCALL));

	always @(*) begin
		// riD = 1'b0;
		case(op_code)
			`R_TYPE:
				case(funct)
					// ��������ָ��
					`ADD,`ADDU,`SUB,`SUBU,`SLTU,`SLT ,
					`AND,`NOR, `OR, `XOR,
					`SLLV, `SLL, `SRAV, `SRA, `SRLV, `SRL,
					`MFHI, `MFLO : begin
						{reg_write_enD, reg_dstD, is_immD} =  4'b1000;
						{mem_to_regD, mem_readD, mem_writeD} =  3'b0;
					end
					// �˳�hilo�����ݡ�jr����Ҫʹ�üĴ����ʹ洢��
					`JR, `MULT, `MULTU, `DIV, `DIVU, `MTHI, `MTLO,
					`SYSCALL, `BREAK : begin
						{reg_write_enD, reg_dstD, is_immD} =  4'b0;
						{mem_to_regD, mem_readD, mem_writeD} =  3'b0;
					end
					`JALR: begin
						{reg_write_enD, reg_dstD, is_immD} =  4'b1100;//xxxxxxxx���о���̫�ԡ�
						{mem_to_regD, mem_readD, mem_writeD} =  3'b0;
					end
					default: begin
						riD  =  1'b1;
						{reg_write_enD, reg_dstD, is_immD}  =  4'b1000;
						{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			// I type

	// ��������ָ��
	// �߼�����
			`ADDI, `SLTI, `SLTIU, `ADDIU, `ANDI, `LUI, `XORI, `ORI: begin
				{reg_write_enD, reg_dstD, is_immD}  =  4'b1_01_1;
				{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
			end

			`BEQ, `BNE, `BLEZ, `BGTZ: begin
				{reg_write_enD, reg_dstD, is_immD}  =  4'b0000;
				{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
			end

			`REGIMM_INST: begin
				case(rt)
					`BGEZAL,`BLTZAL: begin
						{reg_write_enD, reg_dstD, is_immD}  =  4'b1100;//��Ҫд��31
						{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
					end
					`BGEZ,`BLTZ: begin
						{reg_write_enD, reg_dstD, is_immD}  =  4'b0000;
						{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
					end
					default:begin
						riD  =  1'b1;
						{reg_write_enD, reg_dstD, is_immD}  =  4'b0;
						{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end
			
	// �ô�ָ�����������ָ�
			`LW, `LB, `LBU, `LH, `LHU: begin
				{reg_write_enD, reg_dstD, is_immD}  =  4'b1011;
				{mem_to_regD, mem_readD, mem_writeD}  =  3'b110;
			end
			`SW, `SB, `SH: begin
				{reg_write_enD, reg_dstD, is_immD}  =  4'b0001;
				{mem_to_regD, mem_readD, mem_writeD}  =  3'b001;
			end
	
	//  J type
			`J: begin
				{reg_write_enD, reg_dstD, is_immD}  =  4'b0;
				{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
			end

			`JAL: begin
				{reg_write_enD, reg_dstD, is_immD}  =  4'b1100;
				{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
			end

			`SPECIAL3_INST:begin
				case(instrD[25:21])
					`MTC0: begin
						{reg_write_enD, reg_dstD, is_immD}  =  4'b0000;
						{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
					end
					`MFC0: begin
						{reg_write_enD, reg_dstD, is_immD}  =  4'b1010;
						{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
					end
					default: begin
						riD  =  |(instrD[25:0] ^ `ERET);
						{reg_write_enD, reg_dstD, is_immD}  =  4'b0000;
						{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end

			default: begin
				riD  =  1;
				{reg_write_enD, reg_dstD, is_immD}  =  4'b0;
				{mem_to_regD, mem_readD, mem_writeD}  =  3'b0;
			end
		endcase
	end
endmodule
