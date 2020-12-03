onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib red_opt

do {wave.do}

view wave
view structure
view signals

do {red.udo}

run -all

quit -force
