onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib gcm_opt

do {wave.do}

view wave
view structure
view signals

do {gcm.udo}

run -all

quit -force
