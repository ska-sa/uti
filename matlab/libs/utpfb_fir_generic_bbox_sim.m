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

function[dout, result] = utpfb_fir_generic_bbox_sim(varargin)
result = -1; dout = [];
log_group = 'utpfb_fir_generic_bbox_sim_debug';

utlog('entering utpfb_fir_generic_bbox_sim',{'trace', log_group});

defaults = {'debug', 'on'};
args = {varargin{:}, 'defaults', defaults};
[name, temp, results(1)]            = utpar_get({args, 'name'});
[din, temp, results(3)]             = utpar_get({args, 'din'});
[model, temp, results(4)]           = utpar_get({args, 'model'});
[block, temp, results(5)]           = utpar_get({model, 'blocks', name});
[parameters, temp, results(6)]      = utpar_get({block,  'parameters'});
[debug, temp, results(7)]           = utpar_get({args, 'debug'});

if ~isempty(find(results ~= 0)),
  utlog('error getting parameters from varargin',{'error', log_group});
end

% TODO these names may depend on pfb version
[pfb_stages, temp, results(1)]      = utpar_get({parameters, 'PFBSize'});
[n_inputs, temp, results(2)]        = utpar_get({parameters, 'n_inputs'});
[pfb_taps, temp, results(3)]        = utpar_get({parameters, 'TotalTaps'});

%worst case latency 
latency = 2^(pfb_stages-n_inputs)*pfb_taps*2;
utlog(['adding latency of ',num2str(latency),' for pfb size ',num2str(pfb_stages),' ', num2str(2^n_inputs),' inputs, ',num2str(pfb_taps),' taps' ],{log_group});

if ~isempty(find(results ~= 0)),
  utlog('error getting parameters from varargin',{'error', log_group});
  return;
end

ldata = length(din);

synci           = [1;zeros(ldata,1)];
raw_data_in     = {'din',   [zeros(2^n_inputs,1);din]};
raw_sync_in     = {'synci', synci};
raw_inputs      = {raw_sync_in, raw_data_in};

[dr,dc] = size(raw_data_in{2});
[sr,sc] = size(raw_sync_in{2});
utlog('simulating with ',{log_group});
utlog(['din (',num2str(dr),',',num2str(dc),')'], {log_group});
utlog(['synci (',num2str(sr),',',num2str(sc),')'], {log_group});

%simulate!
[raw_outputs, result] = utmodel_sim('model', {model{:}}, 'inputs', raw_inputs, 'sim_time', (ldata/2^n_inputs)+latency);
if result ~= 0,
  utlog('error simulating model', {'error', log_group});
  return;
end

if strcmp(debug, 'on'),
    figure;
    subplot(6,1,1);
    plot(synco);
    subplot(6,1,2);
    plot(dout0);
    subplot(6,1,3);
    plot(dout1);
    subplot(6,1,4);
    plot(dout2);
    subplot(6,1,5);
    plot(dout3);
end; %if debug

raw_dout  = utpar_get({raw_outputs, 'dout'});
raw_synco = utpar_get({raw_outputs, 'synco'});

[dout, temp, result] = utextract('mux', 2^n_inputs, 'data', raw_dout, 'sync', raw_synco);
if result ~= 0, 
  utlog('error extracting data', {'error', log_group});
  return;
end

utlog('exiting utpfb_fir_generic_bbox_sim',{'trace', log_group});
