module decisions (clk,rst_n, go_to_work_i,go_to_beach_i, weather_i, action_o);
input clk,rst_n;
input go_to_work_i,go_to_beach_i;
input [1:0] weather_i;
output reg action_o;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		action_o=0;
	else
		begin
		case(weather_i)
			2'b01:
			action_o=go_to_work_i;
			2'b10:
			action_o=go_to_beach_i;
			default:
			action_o=0;
		endcase
		end
end
endmodule
