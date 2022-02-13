..  Copyright 2014-present PlatformIO <contact@platformio.org>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
       http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

How to build PlatformIO based project
=====================================

1. `Install PlatformIO Core <http://docs.platformio.org/page/core.html>`_
2. Download `development platform with examples <https://github.com/platformio/platform-chipsalliance/archive/develop.zip>`_
3. Extract ZIP archive
4. Run these commands:

.. code-block:: bash

    # Change directory to example
    > cd platform-chipsalliance/examples/native-blink_asm

    # Build project
    > platformio run

    # Upload firmware
    > platformio run --target upload

    # Upload bitstream
    > platformio run --target program_fpga
    
    # Generate trace for GTKWave
    > platformio run --target generate_trace
    
    # Start verilator as JTAG server for OpenOCD
    > platformio run --target start_verilator
    
    # Generate bistream for SweRV Core using Xilinx Vivado
    > platformio run --target generate_bitstream

    # Upload firmware for the specific environment
    > platformio run -e swervolf_nexys --target upload

    # Clean build files
    > platformio run --target clean
