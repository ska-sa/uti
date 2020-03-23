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

function[dout, result] = utfft_bbox_sim(varargin)
ut_log_group = 'utfft_bbox_sim_debug';
utlog('entering utfft_bbox_sim',{'trace', ut_log_group});

result = -1; dout = {};
defaults = {};
args                                = {varargin{:}, 'defaults', defaults};
[name, temp, results(1)]            = utpar_get({args, 'name'});
[fft_shift, temp, results(2)]       = utpar_get({args, 'fft_shift'});
[model, temp, results(4)]           = utpar_get({args, 'model'});
[fft, temp, results(5)]             = utpar_get({model, 'blocks', name});
[parameters, temp, results(6)]      = utpar_get({fft, 'parameters'});
[version, temp, results(8)]         = utpar_get({fft, 'version'});

if ~isempty(find(results ~= 0)),
  utlog('error getting upfront parameters from varargin',{'error', ut_log_group});
end

%TODO make this based on fft type and version
[fft_stages, temp, results(1)]      = utpar_get({parameters, 'FFTSize'});
[n_inputs, temp, results(2)]        = utpar_get({parameters, 'n_inputs'});
[mult_latency, temp, results(3)]    = utpar_get({parameters, 'mult_latency'});
[add_latency, temp, results(4)]     = utpar_get({parameters, 'add_latency'});
[bram_latency, temp, results(5)]    = utpar_get({parameters, 'bram_latency'});
[conv_latency, temp, results(6)]    = utpar_get({parameters, 'conv_latency'});
%TODO check results

if strcmp(version, '1') | strcmp(version, '2'),
  [n_streams, temp, results(7)]     = utpar_get({parameters,'n_streams'});
else,
  n_streams = 1;
end %if

if ~isempty(find(results ~= 0)),
  utlog('error getting parameters from varargin',{'error', ut_log_group});
end

%worst case latency
%TODO put these latency lookups in their own files ?
coeff_latency              = add_latency + 2 + conv_latency + bram_latency + add_latency + 2;
twiddle_latency            = coeff_latency + ceil(log2(n_inputs)) + mult_latency + add_latency + conv_latency;
butterfly_latency          = twiddle_latency + add_latency + 2 + conv_latency;
biplex_core_latency        = sum(2.^(fft_stages-1:-1:0) + 1 + butterfly_latency); %async fft has more latency here 
reorder_latency            = (2^(fft_stages - n_inputs - 1) + 2*bram_latency + 1 + ceil(log2(n_inputs))); %worst case
bi_real_unscr_4x_latency   = reorder_latency + 1 + add_latency + conv_latency + reorder_latency;
fft_biplex_real_4x_latency = biplex_core_latency + bi_real_unscr_4x_latency;
fft_direct_latency         = butterfly_latency * n_inputs;   
square_transposer_latency  = 2^(n_inputs-1)-1 + n_inputs-1;
fft_unscrambler_latency    = square_transposer_latency + reorder_latency;
fft_wideband_real_latency  = fft_biplex_real_4x_latency + fft_direct_latency + fft_unscrambler_latency;
extra_latency              = 1000;
 
latency = fft_wideband_real_latency + extra_latency; %TODO
utlog(['adding latency of ',num2str(latency),' for fft size 2^',num2str(fft_stages),' with 2^', num2str(n_inputs),' input ports' ],{ut_log_group});

%if a later version of fft, we can have multiple input streams
raw_data_in = {}; dr = [];
for n = 0:(n_streams-1),
  dname = ['din',num2str(n)];
  [din, temp, results(1)] = utpar_get({args, dname});
  if ~isempty(find(results ~= 0)),
    utlog(['error getting ',dname],{'error', ut_log_group});
  end
  raw_data_in = {raw_data_in{:}, {dname, [zeros(2^n_inputs,1); din]}}; %raw_data_in
  [rdata,cdata] = size(din); %TODO compare stream lengths
  dr = [dr, rdata+1];
end %for
synci           = [1;zeros(rdata,1)];
shift           = [fft_shift.*ones(1+rdata,1)];

raw_sync_in     = {'synci', synci};
raw_shift_in    = {'shift', shift};
raw_inputs      = {raw_sync_in, raw_shift_in, raw_data_in{:}};

[sr,sc] = size(raw_sync_in{2});
[tr,tc] = size(raw_shift_in{2});
utlog(['simulating with ',num2str(n_streams),' data stream/s'], {ut_log_group});
utlog(['din (',num2str(dr),')'], {ut_log_group});
utlog(['synci (',num2str(sr),')'], {ut_log_group});
utlog(['shift (',num2str(tr),')'], {ut_log_group});

sim_time = (rdata/(2^n_inputs))+latency;
utlog(['simulating for ',num2str(sim_time),' time units'], {ut_log_group});
%simulate!
[raw_outputs, result] = utmodel_sim('model', model, 'inputs', raw_inputs, 'sim_time', sim_time);
if result ~= 0,
  utlog('error simulating model', {'error', ut_log_group});
  return;
end

[raw_of, temp, result] = utpar_get({raw_outputs, 'of'});
if result ~= 0
  utlog(['error getting overflow output'], {'error', ut_log_group});
  return;
end %if
if ~isempty(find(raw_of ~= 0)),
  utlog('overflow during simulation', {'error', ut_log_group});
  warning('overflow during simulation');
%  return;
end

raw_synco       = utpar_get({raw_outputs, 'synco'});
%process output data streams
for n = 1:n_streams,
  d_name = ['dout',num2str(n-1)];
  [raw_dout, temp, result] = utpar_get({raw_outputs, d_name});
  if result ~= 0, 
    utlog(['error getting ',dname],{'error', ut_log_group});
  end

  [d, temp, result] = utextract('mux', 2^(n_inputs-1), 'data', raw_dout, 'sync', raw_synco, 'fold_len', 2^(fft_stages-1));
  if result ~= 0, 
    utlog(['error extracting data stream ',num2str(n)], {'error', ut_log_group});
    return;
  end %if
  dout = {dout{:}, ['dout',num2str(n-1)], d};

end %for

[dor,doc] = size(dout);
[sor,soc] = size(raw_synco);
[ofr,ofc] = size(raw_of);
utlog('simulation results:', {ut_log_group});
utlog(['dout (',num2str(dor),',',num2str(doc),')'], {ut_log_group});
utlog(['synco (',num2str(sor),',',num2str(soc),')'], {ut_log_group});
utlog(['of (',num2str(ofr),',',num2str(ofc),')'], {ut_log_group});

utlog('exiting utfft_bbox_sim',{'trace', ut_log_group});
