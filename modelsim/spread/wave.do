onerror {resume}
quietly WaveActivateNextPane {} 0

# 顶层 (top-level)
add wave -noupdate -label KEY -radix binary /testbench/KEY
add wave -noupdate -label SW  -radix binary -expand /testbench/SW

# 输入 (inputs)
add wave -noupdate -divider inputs
add wave -noupdate -label buy_price  -radix unsigned /testbench/buy_price
add wave -noupdate -label sell_price -radix unsigned /testbench/sell_price

# 输出 (output)
add wave -noupdate -divider spread
add wave -noupdate -label spread -radix unsigned /testbench/U1/spread

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1000 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 120
configure wave -valuecolwidth 60
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {5 us}
