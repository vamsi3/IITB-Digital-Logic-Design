cd 20140524/makestuff/apps/flcli
make deps
cd ../../
scripts/msget.sh makestuff/hdlmake
cd hdlmake/apps
cd makestuff/swled/cksum/vhdl
../../../../../bin/hdlmake.py -t ../../templates/fx2all/vhdl -b atlys -p fpga
../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -i 1443:0007
../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -p J:D0D2D3D4:fpga.xsvf
cd 20140524/makestuff/hdlmake/apps/makestuff/swled/cksum/vhdl
