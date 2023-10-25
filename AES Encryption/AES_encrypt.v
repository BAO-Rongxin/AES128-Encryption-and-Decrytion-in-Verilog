module AES_encrypt(input clk,  //10M
						 input rst_n,
						 input RXD,
						 output TXD,
						 
						 output [3:0] STATE,
						 output UART_TX_EN,
						 output UART_TX_DONE,
						 output UART_RX_DONE,
						 output CTRL,
						 output LD,
						 output DONE,
						 output KEY_LOAD,
						 output finish,
						 output UART_ERROR
						 );
						 
wire [3:0] IDLE = 4'b0001;
wire [3:0] KEY_IN = 4'b0010;
wire [3:0] ENCRYPT = 4'b0100;
wire [3:0] FINISH = 4'b1000;

wire [127:0] text_out_temp;
reg [127:0] text_out;
wire [7:0] data;
reg [7:0] INPUT_BUF [17:0];
reg [127:0] KEY_BUF;
reg [3:0] current_state;
wire [3:0] next_state;
reg rstn_sync0,rstn_sync1;
wire RSTN = rstn_sync1;
reg [4:0] cnt;
assign finish = &cnt;
assign CTRL = (INPUT_BUF[0] == 8'd10) & (INPUT_BUF[1] == 8'd13);
assign LD = (current_state[2]) & CTRL;
assign UART_TX_EN = (current_state[3]) & ~cnt[0];
wire [7:0] uart_din;
assign uart_din = (cnt[4:1] == 4'd15)? text_out[7:0] : 
						(cnt[4:1] == 4'd14)? text_out[15:8] :
						(cnt[4:1] == 4'd13)? text_out[23:16] :
						(cnt[4:1] == 4'd12)? text_out[31:24] :
						(cnt[4:1] == 4'd11)? text_out[39:32] :
						(cnt[4:1] == 4'd10)? text_out[47:40] :
						(cnt[4:1] == 4'd9)? text_out[55:48] :
						(cnt[4:1] == 4'd8)? text_out[63:56] :
						(cnt[4:1] == 4'd7)? text_out[71:64] :
						(cnt[4:1] == 4'd6)? text_out[79:72] :
						(cnt[4:1] == 4'd5)? text_out[87:80] :
						(cnt[4:1] == 4'd4)? text_out[95:88] :
						(cnt[4:1] == 4'd3)? text_out[103:96] :
						(cnt[4:1] == 4'd2)? text_out[111:104] :
						(cnt[4:1] == 4'd1)? text_out[119:112] :
						(cnt[4:1] == 4'd0)? text_out[127:120] :
						8'b0;
assign KEY_LOAD = (current_state[1]) & CTRL;
assign STATE = current_state;

always@(posedge clk) begin  //同步复位信号
	{rstn_sync1,rstn_sync0} <= #1 {rstn_sync0,rst_n};
end

always@(posedge clk) begin  //状态切换
	if(!RSTN) current_state <= #1 IDLE;
	else current_state <= #1 next_state;
end

always@(posedge clk) begin  //发送控制计数器
	if(!RSTN | finish) cnt <= #1 5'b0;
	else if((~cnt[0] & UART_TX_DONE) | (cnt[0])) cnt <= #1 cnt + 1'b1;
end

always@(posedge clk) begin  //控制BUF
	if(!RSTN | CTRL)  {INPUT_BUF[17],INPUT_BUF[16],INPUT_BUF[15],INPUT_BUF[14],INPUT_BUF[13],INPUT_BUF[12],INPUT_BUF[11],INPUT_BUF[10],INPUT_BUF[9],INPUT_BUF[8],INPUT_BUF[7],INPUT_BUF[6],INPUT_BUF[5],INPUT_BUF[4],INPUT_BUF[3],INPUT_BUF[2],INPUT_BUF[1],INPUT_BUF[0]} <= #1 144'b0;
	else if(UART_RX_DONE) {INPUT_BUF[17],INPUT_BUF[16],INPUT_BUF[15],INPUT_BUF[14],INPUT_BUF[13],INPUT_BUF[12],INPUT_BUF[11],INPUT_BUF[10],INPUT_BUF[9],INPUT_BUF[8],INPUT_BUF[7],INPUT_BUF[6],INPUT_BUF[5],INPUT_BUF[4],INPUT_BUF[3],INPUT_BUF[2],INPUT_BUF[1],INPUT_BUF[0]} <= #1 {INPUT_BUF[16],INPUT_BUF[15],INPUT_BUF[14],INPUT_BUF[13],INPUT_BUF[12],INPUT_BUF[11],INPUT_BUF[10],INPUT_BUF[9],INPUT_BUF[8],INPUT_BUF[7],INPUT_BUF[6],INPUT_BUF[5],INPUT_BUF[4],INPUT_BUF[3],INPUT_BUF[2],INPUT_BUF[1],INPUT_BUF[0],data};
end

always@(posedge clk) begin  //缓冲KEY
	if(KEY_LOAD) KEY_BUF <= #1 {INPUT_BUF[17],INPUT_BUF[16],INPUT_BUF[15],INPUT_BUF[14],INPUT_BUF[13],INPUT_BUF[12],INPUT_BUF[11],INPUT_BUF[10],INPUT_BUF[9],INPUT_BUF[8],INPUT_BUF[7],INPUT_BUF[6],INPUT_BUF[5],INPUT_BUF[4],INPUT_BUF[3],INPUT_BUF[2]};
end

always@(posedge clk) begin
	if(DONE) text_out <= #1 text_out_temp;
end

assign next_state = ((current_state[0]) & UART_RX_DONE)? KEY_IN :
						  ((current_state[1]) & CTRL)? ENCRYPT :
						  ((current_state[2]) & DONE)? FINISH :
						  ((current_state[3]) & finish)? ENCRYPT :
						  current_state;

uart_txd   u0( 
	.sys_clk(clk),
	.rst_n(RSTN),
				
	.uart_en(UART_TX_EN),
	.uart_din(uart_din),
	.uart_txd(TXD),
	.uart_done(UART_TX_DONE)
	);
				 
uart_rxd  u1( 
	.sys_clk(clk),
	.rst_n(RSTN),
		
	.UART_RX(RXD),
	.uart_done_pulse(UART_RX_DONE),
	.data(data),
	.uart_error(UART_ERROR)
	);	
				 
aes_cipher_top u2(
	.clk(clk),
	.rst(RSTN), 
				 
	.ld(LD), 
	.done(DONE), 
	.key(KEY_BUF), 
	.text_in({INPUT_BUF[17],INPUT_BUF[16],INPUT_BUF[15],INPUT_BUF[14],INPUT_BUF[13],INPUT_BUF[12],INPUT_BUF[11],INPUT_BUF[10],INPUT_BUF[9],INPUT_BUF[8],INPUT_BUF[7],INPUT_BUF[6],INPUT_BUF[5],INPUT_BUF[4],INPUT_BUF[3],INPUT_BUF[2]}), 
	.text_out(text_out_temp)
	);	 
	
endmodule
