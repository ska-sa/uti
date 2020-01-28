warning off Simulink:Masking:BlockNotMasked
warning off Simulink:Commands:LoadMdlParameterizedLink
warning off Simulink:Commands:OutputNotConnected
warning on verbose
addpath([getenv('XILINX_PATH'), '/ISE/sysgen/util/']);
addpath([getenv('XILINX_PATH'), '/ISE/sysgen/bin/lin64']);
addpath([getenv('MLIB_DEVEL_PATH'), '/casper_library']);
addpath([getenv('MLIB_DEVEL_PATH'), '/xps_library']);
xlAddSysgen([getenv('XILINX_PATH'), '/ISE'])
%uti stuff
uti_root = '/home/uti/matlab';
addpath([uti_root,'/tools']);
addpath([uti_root,'/tools/misc']);
addpath([uti_root,'/tools/par']);
addpath([uti_root,'/tools/data']);
addpath([uti_root,'/tools/inport']);
addpath([uti_root,'/tools/outport']);
addpath([uti_root,'/tools/block']);
addpath([uti_root,'/tools/model']);
addpath([uti_root,'/tools/bbox']);
addpath([uti_root,'/tools/sources']);
addpath([uti_root,'/tools/uti_library']);
addpath([uti_root,'/libs/casper']);
addpath([uti_root,'/libs/casper/pfb_fir']);
addpath([uti_root,'/libs/casper/fft']);
addpath([uti_root,'/apps/casper']);
%generic start
sysgen_startup
load_system('casper_library');
load_system('xps_library');
cd([uti_root,'/apps/casper']);
