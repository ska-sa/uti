function[n_ports, result] = utinport_nports(varargin)
log_group = 'utinport_nports_debug';

utlog('entering utinport_nports', {'trace', log_group});
[n_ports, result] = utoutport_nports(varargin{:});

utlog('exiting utinport_nports', {'trace', log_group});
