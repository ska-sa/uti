%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   SKA Africa                                                                %
%   http://www.kat.ac.za                                                      %
%   Copyright (C) 2016 Andrew Martens (andrew@ska.ac.za)                      %
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

%function to find channel response of casper pfb chain
function[dout, result] = casper_fft_wideband_real_channel_response(varargin)
  warning off Simulink:Engine:OutputNotConnected
  ut_log_group = 'casper_fft_wideband_real_channel_response_debug';

  utlog('entering', {'trace', ut_log_group});

  result = -1; 
  data = []; 

  defaults = { ...
    'n_spectra', 1, ...             % the amount of averaging to perform
    'fft_stages', 11, ...           % size of FFT
    'plots', 'on', ...              % output a plot of the response when done
    'offset', 1, ...                % offset of start frequency in fft bins
    'freq_step', 2^(11-2)+1/7, ... % frequency step for each iteration in fraction of an fft_bin
    'span', 2^11, ...               % frequency span over which to iterate
    'amp', 0.75, ...                % amplitude of sinusoid
    'noise_power', 1/2^11          % power in guassian white noise to add to input sinusoid
  };

  args = {varargin{:}, 'defaults', defaults};
  [fft_stages, temp, results(2)]             = utpar_get({args, 'fft_stages'});
  [offset, temp, results(5)]                 = utpar_get({args, 'offset'});
  [fs, temp, results(6)]                     = utpar_get({args, 'freq_step'});
  [span, temp, results(7)]                   = utpar_get({args, 'span'});
  [amp, temp, results(8)]                    = utpar_get({args, 'amp'});
  [noise_power, temp, results(9)]            = utpar_get({args, 'noise_power'});
  [plots, temp, results(11)]                 = utpar_get({args, 'plots'});
  [n_spectra, temp, results(12)]             = utpar_get({args, 'n_spectra'});

  if ~isempty(find(results ~= 0)),
      utlog('error getting parameters from varargin',{'error', ut_log_group});
      return;
  end

  %%%%%%%%%%%%%%%%%%%
  % system settings %
  %%%%%%%%%%%%%%%%%%%
  
  fft_shift             = 2^fft_stages-1;
  n_inputs              = 2;
  n_bits_in             = 18;
  n_bits_out            = 18;

  %%%%%%%%%%%%%%%%
  % fft settings %   
  %%%%%%%%%%%%%%%%

  fft_model_name        = 'fft_test';
  fft_block_name        = 'fft_wideband_real';
  fft_type              = fft_block_name;
  fft_block_version     = '1';

  fft_n_bits_in         = 18;
  fft_coeff_bit_width   = 18;
  fft_quantization      = 'Round  (unbiased: Even Values)';
  fft_overflow          = 'Saturate';

  %%%%%%%%%%%%%%%%%%
  % fft parameters %
  %%%%%%%%%%%%%%%%%%

  fft_parameters = { ...
      'coeff_bit_width', fft_coeff_bit_width, ...
      'input_bit_width', fft_n_bits_in, ...
      'bin_pt_in', fft_n_bits_in-1, ...
      'n_inputs', n_inputs, ...
      'FFTSize', fft_stages, ...
      'quantization', fft_quantization, ...
      'overflow', fft_overflow, ...
  };

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %construct black box model for erecting
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  fft_block = { ...
    'name', fft_block_name, ...
    'type', fft_type, ...
    'version', fft_block_version, ...
    'parameters', fft_parameters, ...
  }; %block

  [fft_model, result] = utfft_bbox_modelify( ...
    'name', fft_model_name, ...
    'block', fft_block);
  if result ~= 0,
      utlog('error creating fft black box model', {'error', ut_log_group});
      return;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % erect the model if it doesn't already exist %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  sys = find_system('type', 'block_diagram', 'name', fft_model_name);
  if isempty(sys),
    result = utmodel_erect(fft_model{:});
    if result ~= 0,
      utlog('error erecting fft model', {'error', ut_log_group});
      return;
    end
  else, %update if exists
  %TODO should use utmodel_update

  end
  
  response = zeros(2^(fft_stages-1), (span/fs));

  %get response
  for freq_index = offset/fs:1:(offset+span)/fs-1,
    utlog(['iteration ',num2str((freq_index-(offset/fs))+1),' of ' num2str(span/fs)], ut_log_group); 

    %%%%%%%%%%%%%%%%%
    % generate data %
    %%%%%%%%%%%%%%%%%

    n_spectra = n_spectra+1;
    f = freq_index*fs;
    noise = noise_power*randn(1, 2^fft_stages*n_spectra);
    sinusoid = amp*sin(2*pi*f/(2^fft_stages)*[0:(2^fft_stages*n_spectra)-1]);
    din = noise+sinusoid;
    din = din';

    n_spectra = n_spectra-1;

    %%%%%%%%%%%%%%%%%%%%%%%%%
    % push data through fft %
    %%%%%%%%%%%%%%%%%%%%%%%%%
   
    utlog('simulating fft response', {ut_log_group});
    [fft_dout, result] = utfft_bbox_sim( fft_model{:}, ...
        'name', fft_block_name, 'fft_shift', fft_shift, 'din', din, 'debug', 'on');
    if result ~= 0,
      utlog('error black box simulation of fft', {'error', ut_log_group});
      return;
    end 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % perform averaging on the result %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fft_dout_sum = sum(abs(fft_dout(:,1:n_spectra)),2); %sum along rows
 
    response(:, (freq_index-offset/fs)+1) = fft_dout_sum(1:2^(fft_stages-1),1)./n_spectra;
  end %for
  size(response)

  dout = response';  

  if strcmp(plots, 'on'),
    %plot results
    figure;
    plot([offset:fs:(offset+span)-fs], 20*log10(dout));
    title('fft chanel response');
  end

  result = 0;
  utlog('exiting', {'trace', ut_log_group});
end %function
