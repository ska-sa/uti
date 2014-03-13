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

%function to find channel response of casper pfb chain in the presence of dc
function[dout, result] = casper_pfb_dc_channel_response()
  ut_log_group = 'casper_pfb_dc_channel_response_debug';

  utlog('entering', {'trace', ut_log_group});

  result = -1; 
  dout = {}; 
  ref = [];

  params = { ...
    'n_spectra', 128, ...               % number of spectra to average together
    'n_taps', 8, ...                    % number of taps in pfb_fir
    'fft_stages', 5, ...                % size of FFT
    'window_type', 'hamming', ...       % window type
    'fwidth', 1, ...                    % relative width of main lobe in channel response
    'plots', 'off', ...                 % output a plot of the response when done
    'offset', 0, ...                    % offset of start frequency in fft bins
    'freq_step', 1/40, ...              % frequency step for each iteration in fraction of an fft_bin
    'span', 2^3, ...                    % frequency span over which to iterate
    'amp', 0.5, ...                     % amplitude of sinusoid
    'noise_power', 1/2^13, ...          % power in guassian white noise to add to input sinusoid
    'dc_power_range', [0], ... %[2^0/2^10, 2^1/2^10], ... % dc power to add to input sinusoid
  };

  args = params;
  [n_taps, temp, results(1)]                 = utpar_get({args, 'n_taps'});
  [fft_stages, temp, results(2)]             = utpar_get({args, 'fft_stages'});
  [window_type, temp, results(3)]            = utpar_get({args, 'window_type'});
  [fwidth, temp, results(4)]                 = utpar_get({args, 'fwidth'});
  [offset, temp, results(5)]                 = utpar_get({args, 'offset'});
  [fs, temp, results(6)]                     = utpar_get({args, 'freq_step'});
  [span, temp, results(7)]                   = utpar_get({args, 'span'});
  [amp, temp, results(8)]                    = utpar_get({args, 'amp'});
  [noise_power, temp, results(9)]            = utpar_get({args, 'noise_power'});
  [dc_power_range, temp, results(10)]        = utpar_get({args, 'dc_power_range'});
  [plots, temp, results(11)]                 = utpar_get({args, 'plots'});
  [n_spectra, temp, results(12)]             = utpar_get({args, 'n_spectra'});

  if ~isempty(find(results ~= 0)),
      utlog('error getting parameters',{'error', ut_log_group});
      return;
  end

  for dc_index = 1:length(dc_power_range),
    dc_power = dc_power_range(dc_index);
    utlog(['iteration ',num2str(dc_index),' of ', num2str(length(dc_power_range))], ut_log_group);
    utlog(['getting pfb channel response with ',num2str(dc_power),' amplitude dc component'], ut_log_group);

    %use same params but tag on dc_power parameter
    new_params = {params{:}, 'dc_power', dc_power}; 

    %get channel response for specified dc_power level
    [response, result] = casper_pfb_channel_response(new_params{:});
    if result ~= 0,
      utlog(['error getting channel response'], {'error', ut_log_group});
    end

    dout{dc_index} = response;
  
    %if strcmp(plots, 'on'),
      figure;
      plot([offset:fs:(offset+span)-fs], 20*log10(response));
      title(['channel response with ',num2str(dc_power),' dc component']); 
    %end

  end %for

  result = 0;
  utlog('exiting', {'trace', ut_log_group});

end %function
