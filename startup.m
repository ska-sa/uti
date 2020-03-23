warning off Simulink:Masking:BlockNotMasked
warning off Simulink:SL_SaveWithParameterizedLinks_Warning
warning off Simulink:Engine:SaveWithParameterizedLinks_Warning
warning off Simulink:Engine:SaveWithDisabledLinks_Warning
warning off Simulink:Commands:LoadMdlParameterizedLink
warning off Simulink:Commands:OutputNotConnected
warning on verbose

jasper_backend = getenv('JASPER_BACKEND');

%if vivado is to be used
if strcmp(jasper_backend, 'vivado') || isempty(jasper_backend)
  disp('Starting Vivado Sysgen')
  addpath([getenv('MLIB_DEVEL_PATH'), '/casper_library']);
  addpath([getenv('MLIB_DEVEL_PATH'), '/xps_library']);
  addpath([getenv('MLIB_DEVEL_PATH'), '/jasper_library']);
%if ISE is to be used  
elseif strcmp(jasper_backend, 'ise')
  disp('Starting ISE Sysgen')
  addpath([getenv('XILINX_PATH'), '/ISE/sysgen/util/']);
  addpath([getenv('XILINX_PATH'), '/ISE/sysgen/bin/lin64']);
  addpath([getenv('MLIB_DEVEL_PATH'), '/casper_library']);
  addpath([getenv('MLIB_DEVEL_PATH'), '/xps_library']);
  addpath([getenv('MLIB_DEVEL_PATH'), '/jasper_library']);
  xlAddSysgen([getenv('XILINX_PATH'), '/ISE'])
  sysgen_startup
else
  fprintf('Unknown JASPER_BACKEND ''%s''\n', jasper_library);
  % Hopefully helpful in this case
  addpath([getenv('MLIB_DEVEL_PATH'), '/casper_library']);
  addpath([getenv('MLIB_DEVEL_PATH'), '/xps_library']);
  addpath([getenv('MLIB_DEVEL_PATH'), '/jasper_library']);
end

%uti stuff
uti_root = getenv('UTI_PATH');
if isempty(uti_root)
  uti_startup_dir = './'
end

addpath([uti_root,'/tools']);
addpath([uti_root,'/libs']);
addpath([uti_root,'/apps']);
%generic start
load_system('casper_library');
load_system('xps_library');
