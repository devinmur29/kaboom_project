onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib green_fing_opt

do {wave.do}

view wave
view structure
view signals

do {green_fing.udo}

run -all

quit -force
