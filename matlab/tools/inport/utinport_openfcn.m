function utinport_openfcn()
log_group = 'utinport_openfcn_debug';

utlog('entering utinport_openfcn',{'trace', log_group});
blk = gcb;
sys = gcs;
set_param(sys, 'Lock', 'off');

% set up mask
set_param(blk, 'SelfModifiable', 'on');
set_param(blk, 'BackGroundColor', '[0, 0.6, 1]');

set_param(sys, 'Lock', 'on');
utlog('exiting utinport_openfcn',{'trace', log_group});
