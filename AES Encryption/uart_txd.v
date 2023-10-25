//8位数据位，1位停止位，奇校验，主时钟50M，波特率115200
module uart_txd(input sys_clk,
				input rst_n,
				
				input uart_en,
				input [7:0] uart_din,
				output reg uart_txd,
				output uart_done);

//主时钟分频计数器
wire [6:0] BPS_CNT = 87;  //BPS_CNT = 时钟频率 / 波特率
reg [6:0] clk_cnt;

//检测上升沿
reg uart_en_d0;
reg uart_en_d1;
wire en_flag;

//串口
reg [3:0] tx_cnt;
reg tx_flag;
reg [7:0] tx_data;

assign en_flag = (uart_en_d0) & (~uart_en_d1);

//检测下降沿
reg uart_done0,uart_done1;
always@(posedge sys_clk) begin
	if(!rst_n) {uart_done1,uart_done0} <= #1 2'b0;
	else {uart_done1,uart_done0} <= #1 {uart_done0,tx_flag};
end
assign uart_done = uart_done1 & ~uart_done0;

//上升沿检测器
always@(posedge sys_clk)
begin
	if(!rst_n) {uart_en_d1,uart_en_d0} <= #1 2'b0;
	else {uart_en_d1,uart_en_d0} <= #1 {uart_en_d0,uart_en};
end

//检测到en_flag，进入发送状态，拉高tx_flag
always@(posedge sys_clk)
begin
	if(!rst_n)
	begin
		tx_flag <= #1 1'b0;
		tx_data <= #1 8'b0;
	end
	else
		if(en_flag)
		begin
			tx_flag <= #1 1'b1;
			tx_data <= #1 uart_din;
		end
		else
			if(tx_cnt == 4'd11)
			begin
				tx_flag <= #1 1'b0;
				tx_data <= #1 8'b0;
			end
			else
			begin
				tx_flag <= #1 tx_flag;
				tx_data <= #1 tx_data;
			end
end

//进入发送状态，进行时序控制
always@(posedge sys_clk)
begin
	if(!rst_n)
	begin
		clk_cnt <= #1 7'b0;
		tx_cnt <= #1 4'b0;
	end
	else
		if(tx_flag)
		begin
			if(clk_cnt < BPS_CNT - 1'b1)
			begin
				tx_cnt <= #1 tx_cnt;
				clk_cnt <= #1 clk_cnt + 1'b1;
			end
			else
			begin
				clk_cnt <= #1 7'b0;
				tx_cnt <= #1 tx_cnt + 1'b1;
			end
		end
		else
		begin
			clk_cnt <= #1 7'b0;
			tx_cnt <= #1 4'b0;
		end
end

//并转串
always@(posedge sys_clk)
begin
	if(!rst_n)
		uart_txd <= 1'b1;
	else
		if(tx_flag)
			case(tx_cnt)
			4'd0: uart_txd <= #1 1'b0;
			4'd1: uart_txd <= #1 tx_data[0];
			4'd2: uart_txd <= #1 tx_data[1];
			4'd3: uart_txd <= #1 tx_data[2];
			4'd4: uart_txd <= #1 tx_data[3];
			4'd5: uart_txd <= #1 tx_data[4];
			4'd6: uart_txd <= #1 tx_data[5];
			4'd7: uart_txd <= #1 tx_data[6];
			4'd8: uart_txd <= #1 tx_data[7];
			4'd9: uart_txd <= #1 ~(tx_data[0]^tx_data[1]^tx_data[2]^tx_data[3]^tx_data[4]^tx_data[5]^tx_data[6]^tx_data[7]);
			4'd10: uart_txd <= #1 1'b1;
			default:uart_txd <= #1 1'b1;
			endcase
		else
			uart_txd <= #1 1'b1;
end

endmodule
