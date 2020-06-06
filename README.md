# Railway Signal Controller

> This project implements a Railway Signal Controller programmed in VHDL.

This was made as the final project for [CS226 / CS254](https://www.cse.iitb.ac.in/~supratik/courses/cs226/index.html) - **Digital Logic Design + Lab** course in Spring 2018 at Indian Institute of Technology (IIT) Bombay, India. You may want to check out the [problem statement](https://www.cse.iitb.ac.in/~supratik/courses/cs254/spr18/FinalProject/final_project.pdf) for more details on this project.

## Getting Started

### Prerequisites

- Xilinx ISE (recommended) - for running VHDL
- Adept2 - for FPGA mapping with Digilent Atlys board (the board which we use for this project)
- [FPGALink](https://github.com/makestuff/libfpgalink) (2014 edition) - for communication between the Digilent Atlys board and a host machine (PC)

### Setup

Follow the instructions below to get our project running on your local machine.

1. Put the `basic_uart.vhdl`, `encryption.vhdl` and `decryption.vhdl` (present in VHDL directory) in `20140524/makestuff/hdlmake/apps/makestuff/swled/cksum/vhdl/`
2. Replace the `hdlmake.cfg` in `20140524/makestuff/hdlmake/apps/makestuff/swled/cksum/vhdl/` with the given `hdlmake_cksum.cfg` (rename this to `hdlmake.cfg`) file (present in `Constraints` directory)
2. Replace the `hdlmake.cfg` in `20140524/makestuff/hdlmake/apps/makestuff/swled/templates/fx2all/vhdl/` with the given `hdlmake_top.cfg` (rename this to `hdlmake.cfg`) file (present in `Constraints` directory)
3. Put the `network.txt` in `/home/*user*/20140524/makestuff/apps/flcli/` (Replace *user* with the proper username)
4. Please change in line 39, 63, 64 of `main.c` the path of `network.txt` according to the username of the system you are executing in. Replace **** in `/home/****/20140524/makestuff/apps/flcli/network.txt` to the username.
5. Replace the `top_level.vhdl` in `20140524/makestuff/hdlmake/apps/makestuff/swled/templates/fx2all/vhdl/` with the given `top_level.vhdl` (present in `VHDL` directory)
6. Replace the `harness.vhdl` in `20140524/makestuff/hdlmake/apps/makestuff/swled/templates/ with the given harness.vhdl` (present in `VHDL` directory)
7. Replace the `board.ucf` in `20140524/makestuff/hdlmake/apps/makestuff/swled/templates/fx2all/boards/atlys/` in with the given `board.ucf` (present in `VHDL` directory)
8. Put the `debouncer.vhdl` (present in `VHDL` directory) in `20140524/makestuff/hdlmake/apps/makestuff/swled/templates/fx2all/vhdl/`

### Executing the code

Executing the `script.sh` provided in `host/` is equivalent to the below sequential execution except for the command to start the process, `cd` to the `cksum/vhdl` and execute the given start command.

The following are all bash commands.

```bash
cd 20140524/makestuff/apps/flcli
make deps
cd ../../
scripts/msget.sh makestuff/hdlmake
cd hdlmake/apps
cd makestuff/swled/cksum/vhdl
../../../../../bin/hdlmake.py -t ../../templates/fx2all/vhdl -b atlys -p fpga
../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -i 1443:0007
../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -p J:D0D2D3D4:fpga.xsvf
```

The following command starts the process as described.

```bash
../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -b -y
```

This gives us the following output.

<pre>
our key is "11001100110011001100110011000001"
our ack1 is "11011011101101111101111101101110"
our ack2 is "11110000111100001111000011110000"
our position is "00100010" (2,2)
</pre>

Take note that our VHDL code communicates in channels 2 and 3.

### General Comments

The additional folder called libs in `host/` is our attempt to use the `flReadChannelAsyncAwait` and `usbBulkCompletionAwait` with timeout parameters, this was a partial success and needs us to have knowledge about `libusb` package. This is just provided as a proof that we tried to use `flReadChannelAsyncAwait` with timeout, though we are not using it.  

- We used the 20 Feb 2018 convention (discussed during lecture) for sending the data on UART.
- Our code deletes the track info if already present in `network.txt` if the data from FPGA came with `trackexists` as 0, but it does not add entries if `trackexists` from FPGA was 1. 
- For UART communication we can do it by `gtkterm` or our code also works for the optional part with a relay host (we have our own python script for the relay computer provided in the main directory)
- We also provided the `.xsvf` file in `fpga/` just in case if there are issues in compilation.

## Authors

* **Vamsi Krishna Reddy Satti** - [vamsi3](https://github.com/vamsi3)
* Vighnesh Reddy Konda - [scopegeneral](https://github.com/scopegeneral)
* Yaswanth Kumar Orru - [yas777](https://github.com/yas777)
* Lakshmi Narayana Chappidi

## Acknowledgement

- [**Chris McClelland**](https://github.com/makestuff) for the **FPGALink** extension.

## License

This project is licensed under the MIT License - please see the [LICENSE](LICENSE) file for details.