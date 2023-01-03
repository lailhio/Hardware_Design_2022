`timescale 1ns / 1ps

`include "defines2.vh"


module maindec(
		input wire[31:0] instrD,


		output reg sign_exD,          //�������Ƿ�Ϊ������չ
		output reg [1:0] reg_dstD,     	//д�Ĵ���ѡ��  00-> rd, 01-> rt, 10-> д$ra
		output reg is_immD,        //alu srcbѡ�� 0->rd2E, 1->immE
		output reg regwriteD,	//д�Ĵ�����ʹ��
		output reg hilo_wenD,
		output reg mem_readD, mem_writeD,
		output reg memtoregD,         	//resultѡ�� 0->alu_out, 1->read_data
		output reg hilo_to_regD,			// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
		output reg riD,
		output reg breakD, syscallD, eretD, 
		output reg cp0_wenD,
		output reg cp0_to_regD,
		output reg [3:0] aluopD
    );

	//Instruct Divide
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD,rdD;
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];

	assign sign_exD = (|(opD[5:2] ^ 4'b0011));		//0��ʾ�޷�����չ��1��ʾ�з���
	assign hilo_wenD = ~(|( opD^ `R_TYPE )) 		//�����ж��ǲ���R-type
						& (~(|(functD[5:2] ^ 4'b0110)) 			// div divu mult multu 	
							|( ~(|(functD[5:2] ^ 4'b0100)) & functD[0]));

	assign hilo_to_regD = ~(|(opD ^ `R_TYPE)) & (~(|(functD[5:2] ^ 4'b0100)) & ~functD[0]);
														// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	assign cp0_wenD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rs ^ `MFC0));
	assign cp0_to_regD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rs ^ `MTC0));
	assign eretD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rs ^ `ERET));
	
	assign breakD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `BREAK));
	assign syscallD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `SYSCALL));

	always @(*) begin
		// riD = 1'b0;
		case(opD)
			`R_TYPE:begin
				case(funct)
					// ��������ָ��
					`ADD,`ADDU,`SUB,`SUBU,`SLTU,`SLT ,
					`AND,`NOR, `OR, `XOR,
					`SLLV, `SLL, `SRAV, `SRA, `SRLV, `SRL,
					`MFHI, `MFLO : begin
						aluopD<=`R_TYPE_OP;
						{regwriteD, reg_dstD, is_immD} =  4'b1000;
						{memtoregD, mem_readD, mem_writeD} =  3'b0;
					end
					// �˳�hilo�����ݡ�jr����Ҫʹ�üĴ����ʹ洢��
					`JR, `MULT, `MULTU, `DIV, `DIVU, `MTHI, `MTLO,
					`SYSCALL, `BREAK : begin
						aluopD<=`R_TYPE_OP;
						{regwriteD, reg_dstD, is_immD} =  4'b0;
						{memtoregD, mem_readD, mem_writeD} =  3'b0;
					end
					`JALR: begin
						aluopD<=`R_TYPE_OP;
						{regwriteD, reg_dstD, is_immD} =  4'b1100;//xxxxxxxx���о���̫�ԡ�
						{memtoregD, mem_readD, mem_writeD} =  3'b0;
					end
					default: begin
						aluopD<=`USELESS_OP;
						riD  =  1'b1;
						{regwriteD, reg_dstD, is_immD}  =  4'b1000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end
	// ------------------����\�߼�����--------------------------------------
			`ADDI:	begin
				aluopD<=`ADDI_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`SLTI:	begin
				aluopD<=`SLTI_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`SLTIU:	begin
				aluopD<=`SLTIU_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`ADDIU:	begin
				aluopD<=`ADDIU_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`ANDI:	begin
				aluopD<=`ADDI_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`LUI:	begin
				aluopD<=`LUI_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`XORI:	begin
				aluopD<=`XORI_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`ORI:	begin
				aluopD<=`ORI_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
	

			`BEQ, `BNE, `BLEZ, `BGTZ: begin
				aluopD<=`USELESS_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b0000;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end

			`REGIMM_INST: begin
				case(rt)
					`BGEZAL,`BLTZAL: begin
						aluopD<=`USELESS_OP;
						{regwriteD, reg_dstD, is_immD}  =  4'b1100;//��Ҫд��31
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`BGEZ,`BLTZ: begin
						aluopD<=`USELESS_OP;
						{regwriteD, reg_dstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					default:begin
						riD  =  1'b1;
						aluopD<=`USELESS_OP;
						{regwriteD, reg_dstD, is_immD}  =  4'b0;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end
			
	// �ô�ָ�����������ָ�
			`LW, `LB, `LBU, `LH, `LHU: begin
				aluopD<=`MEM_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b110;
			end
			`SW, `SB, `SH: begin
				aluopD<=`MEM_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b0001;
				{memtoregD, mem_readD, mem_writeD}  =  3'b001;
			end
	
	//  J type
			`J: begin
				aluopD<=`USELESS_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b0;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end

			`JAL: begin
				aluopD<=`USELESS_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b1100;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end

			`SPECIAL3_INST:begin
				case(instrD[25:21])
					`MTC0: begin
						aluopD<=`MTC0_OP;
						{regwriteD, reg_dstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`MFC0: begin
						aluopD<=`MFC0_OP;
						{regwriteD, reg_dstD, is_immD}  =  4'b1010;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					default: begin
						aluopD<=`USELESS_OP;
						riD  =  |(instrD[25:0] ^ `ERET);
						{regwriteD, reg_dstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end

			default: begin
				riD  =  1;
				aluopD<=`USELESS_OP;
				{regwriteD, reg_dstD, is_immD}  =  4'b0;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
		endcase
	end
endmodule
