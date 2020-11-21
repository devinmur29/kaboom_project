onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib blue_fing_opt

do {wave.do}

view wave
view structure
view signals

do {blue_fing.udo}

run -all

quit -force
