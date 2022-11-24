# ===================================================================
# TITLE : UART to Avalon-ST bytes stream
#
#   DEGISN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
#   DATE   : 2022/11/25 -> 2022/11/25
#
# ===================================================================
#
# The MIT License (MIT)
# Copyright (c) 2022 J-7SYSTEM WORKS LIMITED.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module uart_to_bytes
# 
set_module_property DESCRIPTION "UART to Avalon-ST bytes stream"
set_module_property NAME uart_to_bytes
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR S.OSAFUNE
set_module_property DISPLAY_NAME uart_to_bytes
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL uart_to_bytes
add_fileset_file uart_module.v VERILOG PATH uart_module.v TOP_LEVEL_FILE


# 
# documentation links
# 
add_documentation_link Github https://github.com/osafune/misc_hdl_module


# 
# parameters
# 
add_parameter CLOCK_FREQUENCY INTEGER 0
set_parameter_property CLOCK_FREQUENCY TYPE INTEGER
set_parameter_property CLOCK_FREQUENCY SYSTEM_INFO {CLOCK_RATE clock}
set_parameter_property CLOCK_FREQUENCY HDL_PARAMETER true
set_parameter_property CLOCK_FREQUENCY VISIBLE false

add_parameter UART_BAUDRATE INTEGER 115200
set_parameter_property UART_BAUDRATE TYPE INTEGER
set_parameter_property UART_BAUDRATE DEFAULT_VALUE 115200
set_parameter_property UART_BAUDRATE DISPLAY_NAME "Bitrate"
set_parameter_property UART_BAUDRATE UNITS bitspersecond
set_parameter_property UART_BAUDRATE HDL_PARAMETER true

add_parameter UART_STOPBIT INTEGER 1
set_parameter_property UART_STOPBIT TYPE INTEGER
set_parameter_property UART_STOPBIT DISPLAY_NAME "Stopbit length"
set_parameter_property UART_STOPBIT DISPLAY_HINT radio
set_parameter_property UART_STOPBIT ALLOWED_RANGES {1:1bit 2:2bit}
set_parameter_property UART_STOPBIT HDL_PARAMETER true


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock

add_interface_port reset reset reset Input 1


# 
# connection point uart
# 
add_interface uart conduit end
set_interface_property uart associatedClock clock
set_interface_property uart associatedReset reset

add_interface_port uart txd txd Output 1
add_interface_port uart rxd rxd Input 1
add_interface_port uart cts cts Input 1
add_interface_port uart rts rts Output 1


# 
# connection point sink
# 
add_interface sink avalon_streaming end
set_interface_property sink associatedClock clock
set_interface_property sink dataBitsPerSymbol 8
set_interface_property sink errorDescriptor ""
set_interface_property sink firstSymbolInHighOrderBits true
set_interface_property sink maxChannel 0
set_interface_property sink readyLatency 0

add_interface_port sink in_data data Input 8
add_interface_port sink in_ready ready Output 1
add_interface_port sink in_valid valid Input 1


# 
# connection point source
# 
add_interface source avalon_streaming start
set_interface_property source associatedClock clock
set_interface_property source dataBitsPerSymbol 8
set_interface_property source errorDescriptor ""
set_interface_property source firstSymbolInHighOrderBits true
set_interface_property source maxChannel 0
set_interface_property source readyLatency 0

add_interface_port source out_data data Output 8
add_interface_port source out_ready ready Input 1
add_interface_port source out_valid valid Output 1
