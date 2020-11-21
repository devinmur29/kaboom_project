onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib fingerprint_rom_opt

do {wave.do}

view wave
view structure
view signals

do {fingerprint_rom.udo}

run -all

quit -force
