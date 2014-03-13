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

function[data, data_ref, result] = casper_pfb_fir_generic_vs_matlab_basic(varargin)
log_group = 'casper_pfb_fir_generic_vs_matlab_basic_debug';

result = -1; data = []; data_ref = [];

%function to compare basic results of matlab pfb_fir vs casper pfb_fir
model_name = 'pfb_fir_generic_test';
block_name = 'pfb_fir_generic';
block_version = '0';

%simulation settings
data_type = 'noise'; 
n_spectra = 10;

noise_power = 2^3/2^8; %1/2^22;

%parameters
n_inputs          = 1;
pfb_size          = 8;
input_bit_width   = 8;
output_bit_width  = 18;
coeff_bit_width   = 18;
quantization      = 'Round  (unbiased: Even Values)';
n_taps            = 4;

parameters = { ...
    'CoeffBitWidth', coeff_bit_width, ...
    'BitWidthIn', input_bit_width, ...
    'BitWidthOut', output_bit_width, ...
    'TotalTaps', n_taps, ... 
    'n_inputs', n_inputs, ...
    'fwidth', 1, ...
    'WindowType', 'hamming', ...
    'PFBSize', pfb_size, ...
    'quantization', quantization};

%system parameters

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%construct black box model for erecting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

block = { ...
  'name', block_name, ...
  'type', 'default', ...
  'version', block_version, ...
  'parameters', parameters, ...
}; %block

[model, result] = utpfb_fir_generic_bbox_modelify( ...
  'name', model_name, ...
  'block', block);
if result ~= 0,
    utlog('error creating black box pfb_fir_generic model', {'error', log_group});
    return;
end

%erect the model if it doesn't already exist
sys = find_system('type', 'block_diagram', 'name', model_name);
if isempty(sys),
  result = utmodel_erect(model{:});
  if result ~= 0,
    utlog('error erecting model', {'error', log_group});
    return;
  end
else, %update if exists
%TODO should use utmodel_update

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simulation data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%raw inputs 
din              = repmat([zeros(1,2^pfb_size*(n_taps-1)), 0.5.*ones(1,2^pfb_size)]', n_spectra, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simulate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[data, result] = utpfb_fir_generic_bbox_sim(model{:}, ...
    'name', block_name, 'din', din, 'debug', 'off');
if result ~= 0,
  utlog('error black box simulating pfb_fir_generic', {'error', log_group});
  return;
end 

%TODO block parameters are actually embedded in model and block
[data_ref, result] = utpfb_fir_generic_sim( ...
    'din', din, ...
    'type', 'pfb_fir_generic', ...
    'version', '0', ...
    'system_parameters', { ...
    }, ...
    'block_parameters', { ...             %parameters used to create pfb_fir
        parameters{:}, ...
    }, ... %block_parameters
    'sim_settings', { ...
        'quantise_input', 'on', ...     %quantise input data before pfb_fir'ing
    }); %utfft_sim

result = 0;


