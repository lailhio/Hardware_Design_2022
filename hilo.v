`timescale 1ns / 1ps
`include "defines2.vh"

module hilo(
   input wire        clk,rst,
   input wire [1:0] hilo_selectE,
   input wire        we, //both write lo and hi
   input wire [31:0] instrM,  
   input wire [63:0] hilo_in,  //存入hilo的值
   
   output wire [31:0] hilo_out
   );
   // hilo寄存器
   reg [63:0] hilo;

   // 更新
   always @(posedge clk) begin
      if(rst)
         hilo <= 0;
      else if(we)
         if(~hilo_selectE[1])//高位为0表示是div或者mult指令
            hilo<=hilo_in;
         else if(hilo_selectE[0])
            hilo[63:32]<=hilo_in[63:32];
         else if(~hilo_selectE[0])
            hilo[31:0]<=hilo_in[31:0];
         else
            hilo<=hilo;
      else
         hilo <= hilo;
   end
   

   // 若为mfhi指令 读hilo高32位  若为mflo指令读hilo低32位
   wire mfhi;
   wire mflo;
   assign mfhi = ~(|(instrM[31:26] ^ `R_TYPE)) & ~(|(instrM[5:0] ^ `MFHI));
   assign mflo = ~(|(instrM[31:26] ^ `R_TYPE)) & ~(|(instrM[5:0] ^ `MFLO));

   assign hilo_out = ({32{mfhi}} & hilo[63:32]) | ({32{mflo}} & hilo[31:0]);
endmodule
