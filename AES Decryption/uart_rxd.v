//8位数据位，1位停止位，偶校验，主时钟5M，波特率115200
`timescale 1ns / 10ps
module uart_rxd(input sys_clk,
				input rst_n,
				
				input UART_RX,
				output wire uart_done_pulse,
				output reg uart_error,
				output reg [7:0] data,
				output reg rx_flag);
//主时钟分频计数
wire [5:0] BPS_CNT = 6'd43;  //BPS_CNT = 时钟频率 / 波特率
reg [5:0] clk_cnt;

//下降沿检测用变量
reg uart_rxd_d0;
reg uart_rxd_d1;
wire start_flag;

//数据变量
reg [3:0] rx_cnt;  //接收数据计数器
reg [8:0] rx_data;  //接收数据寄存器
reg uart_done,uart_done0;

reg RX0,RX1;
always@(posedge sys_clk) begin
	{RX1,RX0} <= #1 {RX0,UART_RX};
end
wire uart_rxd = RX1;

always@(posedge sys_clk) begin
	if(!rst_n) uart_done0 <= #1 1'b0;
	else #1 uart_done0 <= uart_done;
end
assign uart_done_pulse = uart_done & ~uart_done0;

assign start_flag = (~uart_rxd_d0) & (uart_rxd_d1);  //检测到下降沿，产生脉冲

//下降沿检测器
always@(posedge sys_clk) begin
	if(!rst_n) {uart_rxd_d1,uart_rxd_d0} <= #1 2'b0;
	else {uart_rxd_d1,uart_rxd_d0} <= #1 {uart_rxd_d0,uart_rxd};
end

//检测start_flag到达，进入接收状态,拉高rx_flag
always@(posedge sys_clk) begin
	if(!rst_n) rx_flag <= #1 1'b0;
	else if(start_flag) rx_flag <= #1 1'b1;
	else if((rx_cnt == 4'd10) && (clk_cnt == BPS_CNT/2)) rx_flag <= #1 1'b0;
	else rx_flag <= #1 rx_flag;
end

//进入接收状态，进行时序控制
always@(posedge sys_clk) begin
	if(!rst_n) clk_cnt <= #1 6'b0;
	else if(rx_flag)
		if(clk_cnt < BPS_CNT - 1'b1) clk_cnt <= #1 clk_cnt + 1'b1;
		else clk_cnt <= #1 6'b0;
	else clk_cnt <= #1 6'b0;
end

//进入接收状态，进行时序控制
always@(posedge sys_clk) begin
	if(!rst_n) rx_cnt <= #1 4'b0;
	else if(rx_flag)
		if(clk_cnt < BPS_CNT - 1'b1) rx_cnt <= #1 rx_cnt;
		else rx_cnt <= #1 rx_cnt + 1'b1;
	else rx_cnt <= #1 4'b0;
end

//串转并模块
always@(posedge sys_clk) begin
	if(!rst_n) rx_data <= #1 8'b0;
	else if(rx_flag)
		if(clk_cnt == BPS_CNT/2)
			case(rx_cnt)
			4'd1: rx_data[0] <= #1 uart_rxd;
			4'd2: rx_data[1] <= #1 uart_rxd;
			4'd3: rx_data[2] <= #1 uart_rxd;
			4'd4: rx_data[3] <= #1 uart_rxd;
			4'd5: rx_data[4] <= #1 uart_rxd;
			4'd6: rx_data[5] <= #1 uart_rxd;
			4'd7: rx_data[6] <= #1 uart_rxd;
			4'd8: rx_data[7] <= #1 uart_rxd;
			4'd9: rx_data[8] <= #1 uart_rxd;
			default: rx_data <= #1 rx_data;
			endcase
		else rx_data <= #1 rx_data;
	else rx_data <= #1 8'b0;
end

//输出控制
always@(posedge sys_clk) begin
	if(!rst_n)
		data <= #1 8'b0;
	else if(rx_cnt == 4'd10)
		if(~(^rx_data)) data <= #1 rx_data [7:0];
		else data <= #1 8'b0;
	else data <= #1 8'b0;
end

always@(posedge sys_clk) begin
	if(!rst_n) uart_error <= #1 1'b0;
	else if(rx_cnt == 4'd10)
		if(~(^rx_data)) uart_error <= #1 1'b0;
		else uart_error <= #1 1'b1;
	else uart_error <= #1 1'b0;
end

always@(posedge sys_clk) begin
	if(!rst_n) uart_done <= #1 1'b0;
	else if(rx_cnt == 4'd10)
		if(~(^rx_data)) uart_done <= #1 1'b1;
		else uart_done <= #1 1'b0;
	else uart_done <= #1 1'b0;
end

endmodule
