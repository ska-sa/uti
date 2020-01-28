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

function[dout, result] = utpfb_fir_real_sim(varargin)
dout = []; result = -1;
ut_log_group = 'utpfb_fir_real_sim_debug';

utlog('entering', {'trace', ut_log_group});

default_taps = 4;
default_pfb_size = 5;
defaults = { ...
    'din', repmat([zeros(1, 2^default_pfb_size*(default_taps-1)), 0.5*ones(1,2^default_pfb_size)]', 10, 1), ...
    'type', 'pfb_fir_real', ...
    'version', '0', ...
    'system_parameters', { ...
    }, ...
    'block_parameters', { ...             %parameters used to create pfb_fir
        'BitWidthIn', 8, ...  
        'BitWidthOut', 18, ...  
        'TotalTaps', default_taps, ... 
        'PFBSize', default_pfb_size, ...
        'fwidth', 1, ...
        'WindowType', 'hamming', ...
    }, ... %parameters
    'sim_settings', { ...
        'quantise_input', 'on', ... %quantise input data before fft'ing
    }, ... %sim_settings
}; %defaults

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%parameters that don't depend on block 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

args = {varargin{:}, 'defaults', defaults};
[din, temp, results(1)]                 = utpar_get({args, 'din'});
[type, temp, results(2)]                = utpar_get({args, 'type'});
[version, temp, results(3)]             = utpar_get({args, 'version'});
[system_parameters, temp, results(4)]   = utpar_get({args, 'system_parameters'});
[block_parameters, temp, results(5)]    = utpar_get({args, 'block_parameters'});
[sim_settings, temp, results(6)]        = utpar_get({args, 'sim_settings'});

if ~isempty(find(results ~= 0)),
    utlog('error getting parameters from varargin',{'error', ut_log_group});
    return;
end

%TODO parameter checking
[r,c] = size(din);
if c~=1,
    utlog('din must be single column',{'error', ut_log_group});
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%simulation parameters that don't depend on block type or version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%simulation parameters
[quantise_input, temp, results(1)]      = utpar_get({sim_settings, 'quantise_input'});
if ~isempty(find(results ~= 0)),
    utlog('error getting parameters from simulation settings',{'error', ut_log_group});
    return;
end

if strcmp(type, 'pfb_fir_real'),
    if strcmp(version, '0'),
        [n_bits_in, temp, results(1)]       = utpar_get({block_parameters, 'BitWidthIn'});
        [pfb_size, temp, results(2)]        = utpar_get({block_parameters, 'PFBSize'});
        [n_taps, temp, results(3)]          = utpar_get({block_parameters, 'TotalTaps'});
        [window_type, temp, results(4)]     = utpar_get({block_parameters, 'WindowType'});
        [fwidth, temp, results(5)]          = utpar_get({block_parameters, 'fwidth'});
        if ~isempty(find(results ~= 0)),
            utlog('error getting parameters from block parameters',{'error', 'utpfb_fir_generic_sim_debug'});
            return;
        end
    else,
        utlog(['unknown version ',version,' of ',type], {'error', ut_log_group});
        return;
    end %version
else, %unknown fft type
    utlog(['unknown type ',type], {'error', ut_log_group});
end

% quantise data pre PFB if required
if strcmp(quantise_input, 'on'),
    din_fi = fi(din, 1, n_bits_in, n_bits_in-1);
    din = din_fi.data;
end

% determine fir coefficients
alltaps = n_taps*2^pfb_size;
coeffs = window(window_type, alltaps)' .* sinc((fwidth*([0:alltaps-1]/(2^pfb_size)-n_taps/2)));

% starting at the last tap, i.e pipeline with youngest data in final tap 
for tap_index = 0:n_taps-1,
  coeffs_rev(1,tap_index*(2^pfb_size)+1:(tap_index+1)*(2^pfb_size)) = coeffs(1,(n_taps-tap_index-1)*(2^pfb_size)+1:(n_taps-tap_index)*(2^pfb_size));
end

% cut off any excess data
din = din(1:floor(length(din)/(2^pfb_size))*(2^pfb_size));

for index = 0:((length(din)/(2^pfb_size))-(n_taps-1))-1,
  unsummed = din(index*(2^pfb_size)+1:(index+n_taps)*(2^pfb_size)).*coeffs';
  summed = sum(reshape(unsummed, 2^pfb_size, n_taps)');

  dout(index*(2^pfb_size)+1:(index+1)*(2^pfb_size),1) = summed;
end %for

% scale data based on max potential gain through filter 
all_filters = reshape(coeffs, 2^pfb_size, n_taps);
% Compute max gain (make sure it is at least 1).
% NB: sum rows, not columns!
max_gain = max(sum(abs(all_filters), 2));
if max_gain < 1; max_gain = 1; end
% Compute bit growth
scale_factor = nextpow2(max_gain);

dout = dout./(2^scale_factor);

result = 0; 
utlog('exiting', {'trace', ut_log_group});
