module AES_MODULE (
	input sys_clk,
	input rst_n,
	input RXD,
	output TXD,
	output CTRL,
	output UART_TX_EN,
	output UART_TX_DONE,
	output UART_RX_DONE,
	output UART_RX_ERROR,
	output [3:0] STATE,
	output KDONE,
	output DONE,
	output LD,
	output KLD,
	output SEND_DONE,
	output UART_RX_FLAG,
	output UART_TX_FLAG
	);

	
wire [3:0] IDLE = 4'b0001;
wire [3:0] KEY_LOAD = 4'b0010;
wire [3:0] WAIT_FOR_TEXT = 4'b0100;
wire [3:0] FINISH_AND_SEND = 4'b1000;

//state signal definition
reg [3:0] current_state;
wire [3:0] next_state;

//data transfer definition
wire [127:0] text_out;
wire [127:0] text_in;
wire [127:0] key;
reg [127:0] OUTPUT_BUF;
wire [7:0] rx_data;
wire [7:0] tx_data;
reg [4:0] uart_tx_counter;
reg [7:0] INPUT_BUF [17:0];

assign next_state = ((current_state & IDLE) && CTRL)? KEY_LOAD :
						  ((current_state & KEY_LOAD) && KDONE)? WAIT_FOR_TEXT :
						  ((current_state & WAIT_FOR_TEXT) && DONE)? FINISH_AND_SEND :
						  ((current_state & FINISH_AND_SEND) && SEND_DONE)? WAIT_FOR_TEXT :
						  current_state;
						  
assign tx_data = (uart_tx_counter[4:1] == 4'd15)? OUTPUT_BUF[7:0] : 
					  (uart_tx_counter[4:1] == 4'd14)? OUTPUT_BUF[15:8] :
					  (uart_tx_counter[4:1] == 4'd13)? OUTPUT_BUF[23:16] :
					  (uart_tx_counter[4:1] == 4'd12)? OUTPUT_BUF[31:24] :
					  (uart_tx_counter[4:1] == 4'd11)? OUTPUT_BUF[39:32] :
					  (uart_tx_counter[4:1] == 4'd10)? OUTPUT_BUF[47:40] :
					  (uart_tx_counter[4:1] == 4'd9)? OUTPUT_BUF[55:48] :
					  (uart_tx_counter[4:1] == 4'd8)? OUTPUT_BUF[63:56] :
					  (uart_tx_counter[4:1] == 4'd7)? OUTPUT_BUF[71:64] :
					  (uart_tx_counter[4:1] == 4'd6)? OUTPUT_BUF[79:72] :
					  (uart_tx_counter[4:1] == 4'd5)? OUTPUT_BUF[87:80] :
					  (uart_tx_counter[4:1] == 4'd4)? OUTPUT_BUF[95:88] :
					  (uart_tx_counter[4:1] == 4'd3)? OUTPUT_BUF[103:96] :
					  (uart_tx_counter[4:1] == 4'd2)? OUTPUT_BUF[111:104] :
					  (uart_tx_counter[4:1] == 4'd1)? OUTPUT_BUF[119:112] :
					  (uart_tx_counter[4:1] == 4'd0)? OUTPUT_BUF[127:120] :
					  8'b0;

assign CTRL = (INPUT_BUF[0] == 8'h0A) & (INPUT_BUF[1] == 8'h0D);
assign KLD = (current_state & IDLE) && CTRL;
assign LD = (current_state & WAIT_FOR_TEXT) && CTRL;
assign text_in = {INPUT_BUF[17],INPUT_BUF[16],INPUT_BUF[15],INPUT_BUF[14],INPUT_BUF[13],INPUT_BUF[12],INPUT_BUF[11],INPUT_BUF[10],INPUT_BUF[9],INPUT_BUF[8],INPUT_BUF[7],INPUT_BUF[6],INPUT_BUF[5],INPUT_BUF[4],INPUT_BUF[3],INPUT_BUF[2]};
assign key = {INPUT_BUF[17],INPUT_BUF[16],INPUT_BUF[15],INPUT_BUF[14],INPUT_BUF[13],INPUT_BUF[12],INPUT_BUF[11],INPUT_BUF[10],INPUT_BUF[9],INPUT_BUF[8],INPUT_BUF[7],INPUT_BUF[6],INPUT_BUF[5],INPUT_BUF[4],INPUT_BUF[3],INPUT_BUF[2]};
assign SEND_DONE = & uart_tx_counter;
assign UART_TX_EN = (current_state & FINISH_AND_SEND) && ~uart_tx_counter[0];

assign STATE = current_state;

//eliminate metastable state
reg rst_n0,rst_n1;
wire NRST = rst_n1;
always@(posedge sys_clk) begin
	{rst_n1,rst_n0} <= #1 {rst_n0,rst_n};
end

//DATA and CTRL input
always@(posedge sys_clk) begin  //控制BUF
	if(!NRST | CTRL)  {INPUT_BUF[1],INPUT_BUF[0]} <= #1 16'b0;
	else if(UART_RX_DONE) {INPUT_BUF[1],INPUT_BUF[0]} <= #1 {INPUT_BUF[0],rx_data};
end

//DATA shifter
always@(posedge sys_clk) begin
	if(UART_RX_DONE) {INPUT_BUF[17],INPUT_BUF[16],INPUT_BUF[15],INPUT_BUF[14],INPUT_BUF[13],INPUT_BUF[12],INPUT_BUF[11],INPUT_BUF[10],INPUT_BUF[9],INPUT_BUF[8],INPUT_BUF[7],INPUT_BUF[6],INPUT_BUF[5],INPUT_BUF[4],INPUT_BUF[3],INPUT_BUF[2]} <= #1 {INPUT_BUF[16],INPUT_BUF[15],INPUT_BUF[14],INPUT_BUF[13],INPUT_BUF[12],INPUT_BUF[11],INPUT_BUF[10],INPUT_BUF[9],INPUT_BUF[8],INPUT_BUF[7],INPUT_BUF[6],INPUT_BUF[5],INPUT_BUF[4],INPUT_BUF[3],INPUT_BUF[2],INPUT_BUF[1]};
end

//STATE Control
always@(posedge sys_clk) begin
	if(!NRST) current_state <= #1 IDLE;
	else current_state <= #1 next_state;
end

//uart_tx_counter control
always@(posedge sys_clk) begin
	if(!NRST | SEND_DONE) uart_tx_counter <= #1 5'b0;
	else if((~uart_tx_counter[0] & UART_TX_DONE) | (uart_tx_counter[0])) uart_tx_counter <= #1 uart_tx_counter + 1'b1;
end

//OUTPUT_BUF Control
always@(posedge sys_clk) begin
	if(DONE) OUTPUT_BUF <= #1 text_out;
end

//AES DECRYPT INITIATE
aes_inv_cipher_top AES_INV(
	.clk        (sys_clk), 
	.rst        (NRST), 
	.kld        (KLD), 
	.ld         (LD), 
	.done       (DONE), 
	.kdone      (KDONE),
	.key        (key), 
	.text_in    (text_in), 
	.text_out   (text_out) 
	);
	
//UART RX INITIATE
uart_rxd UART_RXD(
	.sys_clk            (sys_clk),
	.rst_n              (NRST),

	.UART_RX            (RXD),
	.uart_done_pulse    (UART_RX_DONE),
	.uart_error         (UART_RX_ERROR),
	.data               (rx_data),
	.rx_flag            (UART_RX_FLAG)
	);
	
//UART TX INITIATE
uart_txd UART_TXD(
	.sys_clk     (sys_clk),
	.rst_n       (NRST),

	.uart_en     (UART_TX_EN),
	.uart_din    (tx_data),
	.uart_txd    (TXD),
	.uart_done   (UART_TX_DONE),
	.tx_flag     (UART_TX_FLAG)
	);

endmodule
