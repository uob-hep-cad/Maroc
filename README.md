# Firmware and support scripts to read out pc043 5-Maroc board.

To setup Xilinx software environment (Vivado) on Bristol Linux PCs:
```
. /software/CAD/Xilinx/2020.2/Vivado/2020.2/settings64.sh
```

To build the firmware:

```
mkdir work
cd work
curl -L https://github.com/ipbus/ipbb/archive/refs/tags/dev/2021i.tar.gz | tar xvz
source ipbb-dev-2021i/env.sh 
ipbb init build
cd build

ipbb add git https://github.com/ipbus/ipbus-firmware.git -b v1.6
ipbb add git https://github.com/ipbus-contrib/enclustra.git
ipbb add git https://github.com/uob-hep-cad/Maroc.git

ipbb proj create vivado top_a35_pc043a Maroc:projects/pc043a_5maroc top_pc043a.dep 

cd proj/top_a35_pc043a
ipbb vivado project
ipbb vivado impl
ipbb vivado bitfile
ipbb vivado memcfg
ipbb vivado package
deactivate
```

After performing the build sequence the FPGA bitfile, PROM programming file and IPBus address map should be contained in `work/build/proj/top_a35_pc043a/package/top_a35_pc043a_XXXXX_YYYY_ZZZZ.tgz` where `XXXX` is the name of the build machine, `YYYY` is the date and `ZZZZ` is the time.

N.B. If you want to *modify* the code rather than just build the configuration files you probably want to use the repository URL that uses ssh shared keys ( git@github.com:uob-hep-cad/Maroc.git ) rather than the HTTP access
