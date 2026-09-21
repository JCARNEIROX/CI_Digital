
//input ports
add mapped point clk clk -type PI PI
add mapped point rst_n rst_n -type PI PI
add mapped point go_to_work_i go_to_work_i -type PI PI
add mapped point go_to_beach_i go_to_beach_i -type PI PI
add mapped point weather_i[1] weather_i[1] -type PI PI
add mapped point weather_i[0] weather_i[0] -type PI PI

//output ports
add mapped point action_o action_o -type PO PO

//inout ports




//Sequential Pins
add mapped point action_o/q action_o_reg/Q -type DFF DFF



//Black Boxes



//Empty Modules as Blackboxes
