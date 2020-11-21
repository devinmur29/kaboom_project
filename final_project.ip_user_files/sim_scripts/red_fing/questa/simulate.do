onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib red_fing_opt

do {wave.do}

view wave
view structure
view signals

do {red_fing.udo}

run -all

quit -force
