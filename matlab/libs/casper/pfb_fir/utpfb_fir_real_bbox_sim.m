%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   SKA Africa                                                                %
%   http://www.kat.ac.za                                                      %
%   Copyright (C) 2013 Andrew Martens (andrew@ska.ac.za)                      %
%                                                                             %
%   This program is free software; you can redistribute it and/or modify      %
%   it under the terms of the GNU General Public License as published by      %
%   the Free Software Foundation; either version 2 of the License, or         %
%   (at your option) any later version.                                       %
%                                                                             %
%   This program is distributed in the hope that it will be useful,           %
%   but WITHOUT ANY WARRANTY; without even the implied warranty of            %
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             %
%   GNU General Public License for more details.                              %
%                                                                             %
%   You should have received a copy of the GNU General Public License along   %
%   with this program; if not, write to the Free Software Foundation, Inc.,   %
%   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.               %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function[dout, result] = utpfb_fir_real_bbox_sim(varargin)
dout = []; result = -1;
ut_log_group = 'utpfb_fir_real_bbox_sim_debug';

utlog('entering',{'trace', ut_log_group});

[din, result] = utdata_gen('sources', {'noise', {'power', 2^0/2^12}} , 'vec_len', 32*2^6);

defaults = { ...
  'name', 'pfb_fir_real', ...
  'din',  din, ... %[0;0;0;0;0;1;0;0;zeros(2^5*4-8,1)], ...
  'model', { ... 
    'name', 'pfb_fir_real_test', ...
    'blocks', { ...
      'pfb_fir_real', { ...
        'parameters', { ...
          'PFBSize', 5, ...
          'n_inputs', 2, ...
        }, ... %parameters
      }, ... %pfb_fir_real
      'inputs', { ...
        'parameters', { ...
          'ports',  { ... %input port description from model
            {'synci', {'parallelisation', 1, 'complex', 'off'}}, ...
            {'din',   {'parallelisation', 4, 'complex', 'off'}}, ...
          }, ... %ports
        }, ... %parameters
      }, ... %inputs
      'outputs', { ...
        'parameters', { ...
          'ports', { ... %output port description from model
            {'dout',  {'complex', 'off',  'parallelisation', 4}}, ...
            {'synco', {'complex', 'off', 'parallelisation', 1}}, ...
          }, ... %ports
        }, ... %parameters
      }, ... %outputs
    }, ... %blocks
  }, ... %model
  'debug', 'on'};
args = {varargin{:}, 'defaults', defaults};
[name, temp, results(1)]            = utpar_get({args,  'name'});
[din, temp, results(3)]             = utpar_get({args,  'din'});
[model, temp, results(4)]           = utpar_get({args,  'model'});
[block, temp, results(5)]           = utpar_get({model, 'blocks', name});
[parameters, temp, results(6)]      = utpar_get({block, 'parameters'});
[debug, temp, results(7)]           = utpar_get({args,  'debug'});

if ~isempty(find(results ~= 0)),
  utlog('error getting parameters from varargin',{'error', ut_log_group});
end

%TODO make this based on pfb type and version
[pfb_stages, temp, results(1)]      = utpar_get({parameters, 'PFBSize'});
[n_inputs, temp, results(2)]        = utpar_get({parameters, 'n_inputs'});
[pfb_taps, temp, results(3)]        = utpar_get({parameters, 'TotalTaps'});

if ~isempty(find(results ~= 0)),
  utlog('error getting parameters from varargin',{'error', ut_log_group});
  return;
end

ldata = length(din);

raw_data_in     = {'din',   [zeros(2^n_inputs,1); din]};
raw_sync_in     = {'synci', [1; zeros(ldata/(2^n_inputs),1)] };
raw_inputs      = {raw_sync_in, raw_data_in};

[dr,dc] = size(raw_data_in{2});
[sr,sc] = size(raw_sync_in{2});
utlog('simulating with ',{ut_log_group});
utlog(['din (',num2str(dr),',',num2str(dc),')'], {ut_log_group});
utlog(['synci (',num2str(sr),',',num2str(sc),')'], {ut_log_group});

%worst case latency 
latency = 2^(pfb_stages-n_inputs)*pfb_taps*2;
utlog(['adding latency of ',num2str(latency),' for pfb size ',num2str(pfb_stages),' ', num2str(2^n_inputs),' inputs, ',num2str(pfb_taps),' taps' ],{ut_log_group});

%simulate!
[raw_outputs, result] = utmodel_sim('model', model, 'inputs', raw_inputs, 'sim_time', (ldata/2^n_inputs)+latency);
if result ~= 0,
  utlog('error simulating model', {'error', ut_log_group});
  return;
end

raw_dout  = utpar_get({raw_outputs, 'dout'});
raw_synco = utpar_get({raw_outputs, 'synco'});

clog('extracting data', {ut_log_group});
[dout, temp, result] = utextract('mux', 2^n_inputs, 'data', raw_dout, 'sync', raw_synco, 'fold_len', 2^pfb_stages);
if result ~= 0, 
  utlog('error extracting data', {'error', ut_log_group});
  return;
end

if strcmp(debug, 'on'),
  figure;
  subplot(3,1,1);
  plot(raw_synco);
  title('raw sync');
  subplot(3,1,2);
  plot(raw_dout);
  title('raw data');
  subplot(3,1,3);
  plot(dout);
  title('pfb fir response');
end

utlog('exiting',{'trace', ut_log_group});
