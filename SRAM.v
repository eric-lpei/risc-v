
`timescale 1ns/100fs

module SRAM2RW16x32M (A1,A2,CE1,CE2,WEB1,WEB2,OEB1,OEB2,CSB1,CSB2,BYTEMASK1,BYTEMASK2,I1,I2,O1,O2);

  input 			CE1;
  input 			CE2;
  input 			WEB1;
  input 			WEB2;
  input 			OEB1;
  input 			OEB2;
  input 			CSB1;
  input 			CSB2;
  input	[4-1:0]		BYTEMASK1;
  input	[4-1:0]		BYTEMASK2;

  input 	[4-1:0] 	A1;
  input 	[4-1:0] 	A2;
  input 	[32-1:0] 	I1;
  input 	[32-1:0] 	I2;
  output 	[32-1:0] 	O1;
  output 	[32-1:0] 	O2;

  SRAM2RW16x8 bank_0 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[0],WEB2 | ~BYTEMASK2[0],OEB1,OEB2,CSB1,CSB2,
    I1[7:0],I2[7:0],O1[7:0],O2[7:0]
  );
  SRAM2RW16x8 bank_1 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[1],WEB2 | ~BYTEMASK2[1],OEB1,OEB2,CSB1,CSB2,
    I1[15:8],I2[15:8],O1[15:8],O2[15:8]
  );
  SRAM2RW16x8 bank_2 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[2],WEB2 | ~BYTEMASK2[2],OEB1,OEB2,CSB1,CSB2,
    I1[23:16],I2[23:16],O1[23:16],O2[23:16]
  );
  SRAM2RW16x8 bank_3 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[3],WEB2 | ~BYTEMASK2[3],OEB1,OEB2,CSB1,CSB2,
    I1[31:24],I2[31:24],O1[31:24],O2[31:24]
  );

endmodule

module SRAM2RW32x32M (A1,A2,CE1,CE2,WEB1,WEB2,OEB1,OEB2,CSB1,CSB2,BYTEMASK1,BYTEMASK2,I1,I2,O1,O2);

  input 			CE1;
  input 			CE2;
  input 			WEB1;
  input 			WEB2;
  input 			OEB1;
  input 			OEB2;
  input 			CSB1;
  input 			CSB2;
  input	[4-1:0]		BYTEMASK1;
  input	[4-1:0]		BYTEMASK2;

  input 	[5-1:0] 	A1;
  input 	[5-1:0] 	A2;
  input 	[32-1:0] 	I1;
  input 	[32-1:0] 	I2;
  output 	[32-1:0] 	O1;
  output 	[32-1:0] 	O2;

  SRAM2RW32x8 bank_0 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[0],WEB2 | ~BYTEMASK2[0],OEB1,OEB2,CSB1,CSB2,
    I1[7:0],I2[7:0],O1[7:0],O2[7:0]
  );
  SRAM2RW32x8 bank_1 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[1],WEB2 | ~BYTEMASK2[1],OEB1,OEB2,CSB1,CSB2,
    I1[15:8],I2[15:8],O1[15:8],O2[15:8]
  );
  SRAM2RW32x8 bank_2 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[2],WEB2 | ~BYTEMASK2[2],OEB1,OEB2,CSB1,CSB2,
    I1[23:16],I2[23:16],O1[23:16],O2[23:16]
  );
  SRAM2RW32x8 bank_3 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[3],WEB2 | ~BYTEMASK2[3],OEB1,OEB2,CSB1,CSB2,
    I1[31:24],I2[31:24],O1[31:24],O2[31:24]
  );

endmodule

module SRAM2RW64x32M (A1,A2,CE1,CE2,WEB1,WEB2,OEB1,OEB2,CSB1,CSB2,BYTEMASK1,BYTEMASK2,I1,I2,O1,O2);

  input 			CE1;
  input 			CE2;
  input 			WEB1;
  input 			WEB2;
  input 			OEB1;
  input 			OEB2;
  input 			CSB1;
  input 			CSB2;
  input	[4-1:0]		BYTEMASK1;
  input	[4-1:0]		BYTEMASK2;

  input 	[6-1:0] 	A1;
  input 	[6-1:0] 	A2;
  input 	[32-1:0] 	I1;
  input 	[32-1:0] 	I2;
  output 	[32-1:0] 	O1;
  output 	[32-1:0] 	O2;

  SRAM2RW64x8 bank_0 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[0],WEB2 | ~BYTEMASK2[0],OEB1,OEB2,CSB1,CSB2,
    I1[7:0],I2[7:0],O1[7:0],O2[7:0]
  );
  SRAM2RW64x8 bank_1 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[1],WEB2 | ~BYTEMASK2[1],OEB1,OEB2,CSB1,CSB2,
    I1[15:8],I2[15:8],O1[15:8],O2[15:8]
  );
  SRAM2RW64x8 bank_2 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[2],WEB2 | ~BYTEMASK2[2],OEB1,OEB2,CSB1,CSB2,
    I1[23:16],I2[23:16],O1[23:16],O2[23:16]
  );
  SRAM2RW64x8 bank_3 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[3],WEB2 | ~BYTEMASK2[3],OEB1,OEB2,CSB1,CSB2,
    I1[31:24],I2[31:24],O1[31:24],O2[31:24]
  );

endmodule

module SRAM2RW128x32M (A1,A2,CE1,CE2,WEB1,WEB2,OEB1,OEB2,CSB1,CSB2,BYTEMASK1,BYTEMASK2,I1,I2,O1,O2);

  input 			CE1;
  input 			CE2;
  input 			WEB1;
  input 			WEB2;
  input 			OEB1;
  input 			OEB2;
  input 			CSB1;
  input 			CSB2;
  input	[4-1:0]		BYTEMASK1;
  input	[4-1:0]		BYTEMASK2;

  input 	[7-1:0] 	A1;
  input 	[7-1:0] 	A2;
  input 	[32-1:0] 	I1;
  input 	[32-1:0] 	I2;
  output 	[32-1:0] 	O1;
  output 	[32-1:0] 	O2;

  SRAM2RW128x8 bank_0 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[0],WEB2 | ~BYTEMASK2[0],OEB1,OEB2,CSB1,CSB2,
    I1[7:0],I2[7:0],O1[7:0],O2[7:0]
  );
  SRAM2RW128x8 bank_1 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[1],WEB2 | ~BYTEMASK2[1],OEB1,OEB2,CSB1,CSB2,
    I1[15:8],I2[15:8],O1[15:8],O2[15:8]
  );
  SRAM2RW128x8 bank_2 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[2],WEB2 | ~BYTEMASK2[2],OEB1,OEB2,CSB1,CSB2,
    I1[23:16],I2[23:16],O1[23:16],O2[23:16]
  );
  SRAM2RW128x8 bank_3 (
    A1,A2,CE1,CE2,WEB1 | ~BYTEMASK1[3],WEB2 | ~BYTEMASK2[3],OEB1,OEB2,CSB1,CSB2,
    I1[31:24],I2[31:24],O1[31:24],O2[31:24]
  );

endmodule
