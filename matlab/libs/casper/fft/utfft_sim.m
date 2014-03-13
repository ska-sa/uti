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

function[dout, result] = utfft_sim(varargin)
log_group = 'utfft_sim_debug';

dout = []; result = -1;

utlog('entering utfft_sim', {'trace', log_group});

defaults = { ...
    'din', 0.5*sin([0:31]*2*pi*5/32)', ...
    'type', 'fft_wideband_real', ...
    'version', '0', ...
    'system_parameters', { ...
        'shift_schedule', 2^5-1, ...
    }, ...
    'block_parameters', { ...             %parameters used to create FFT
        'input_bit_width', 18, ...  
        'FFTSize', 5, ...
    }, ... %parameters
    'sim_settings', { ...
        'quantise_input', 'on', ... %quantise input data before fft'ing
        'shift', 'on', ...          %simulate result of shift schedule
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
    utlog('error getting parameters from varargin',{'error', log_group});
    return;
end

%TODO parameter checking
[r,c] = size(din);
if c~=1,
    utlog('din must be single column',{'error', log_group});
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%simulation parameters that don't depend on block type or version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% system parameters needed for ffts
%TODO shift can be hard-coded so should only read if FFT not set to use hard-coded
[shift_schedule, temp, results(1)]      = utpar_get({system_parameters, 'shift_schedule'});
if ~isempty(find(results ~= 0)),
    utlog('error getting parameters from system parameters',{'error', log_group});
    return;
end

%simulation parameters for fft
[quantise_input, temp, results(1)]      = utpar_get({sim_settings, 'quantise_input'});
[shift, temp, results(2)]               = utpar_get({sim_settings, 'shift'});
if ~isempty(find(results ~= 0)),
    utlog('error getting parameters from simulation settings',{'error', log_group});
    return;
end

if strcmp(type, 'fft_wideband_real'),
    if strcmp(version, '0'),
        [input_bit_width, temp, results(1)]     = utpar_get({block_parameters, 'input_bit_width'});
        [fft_stages, temp, results(2)]          = utpar_get({block_parameters, 'FFTSize'});
        if ~isempty(find(results ~= 0)),
            utlog('error getting parameters from block parameters',{'error', log_group});
            return;
        end
    else,
        utlog(['unknown version ',version,' of ',type], {'error', log_group});
        return;
    end %version
else, %unknown fft type
    utlog(['unknown fft type ',type], {'error', log_group});
end

%quantise data pre FFT if required
if strcmp(quantise_input, 'on'),
    din_fi = fi(din, 1, input_bit_width, input_bit_width-1);
    din = din_fi.data;
end

%reshape data into columns for input to fft
n_spectra = floor(r/(2^fft_stages));
din = reshape(din(1:n_spectra*(2^fft_stages),1), 2^fft_stages, n_spectra);

%fft data
dout = fft(din, 2^fft_stages);

%truncate spectrum depending on fft type
if strcmp(type, 'fft_wideband_real'),
    if strcmp(version, '0'),
        dout = dout(1:2^(fft_stages-1),:);
    else,
        utlog(['unknown version ',version,' of ',type], {'error', log_group});
        return;
    end %version
else,
    utlog(['unknown fft type ',type], {'error', log_group});
end

%scale data
if strcmp(shift, 'on'),
    factor = sum(str2num(dec2bin(shift_schedule)')); %figure out scaling factor
    utlog(['scaling by ',num2str(2^factor),'(0x',dec2hex(shift_schedule),')'], log_group);
    dout = dout./(2^factor);
end

result = 0; 
utlog('exiting utfft_sim', {'trace', log_group});
