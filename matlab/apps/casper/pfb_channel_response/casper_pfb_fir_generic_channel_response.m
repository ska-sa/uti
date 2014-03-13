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

%function to find channel response of casper pfb chain
function[dout, result] = casper_pfb_fir_generic_channel_response(varargin)
  warning off Simulink:Engine:OutputNotConnected
  ut_log_group = 'casper_pfb_fir_generic_channel_response_debug';

  utlog('entering', {'trace', ut_log_group});

  result = -1; 
  data = []; 

  defaults = { ...
    'n_spectra', 8, ...             % the amount of averaging to perform
    'n_taps', 4, ...                % number of taps in pfb_fir
    'fft_stages', 16, ...           % size of FFT
    'window_type', 'hamming', ...   % window type
    'fwidth', 1, ...                % relative width of main lobe in channel response
    'plots', 'off', ...             % output a plot of the response when done
    'offset', 0, ...                % offset of start frequency in fft bins
    'freq_step', 1/15, ...          % frequency step for each iteration in fraction of an fft_bin
    'span', 3, ...                  % frequency span over which to iterate
    'amp', 0.5, ...                 % amplitude of sinusoid
    'noise_power', 1/2^13, ...      % power in guassian white noise to add to input sinusoid
    'dc_power', 0, ...              % dc power to add to input sinusoid
  };

  args = {varargin{:}, 'defaults', defaults};
  [n_taps, temp, results(1)]                 = utpar_get({args, 'n_taps'});
  [fft_stages, temp, results(2)]             = utpar_get({args, 'fft_stages'});
  [window_type, temp, results(3)]            = utpar_get({args, 'window_type'});
  [fwidth, temp, results(4)]                 = utpar_get({args, 'fwidth'});
  [offset, temp, results(5)]                 = utpar_get({args, 'offset'});
  [fs, temp, results(6)]                     = utpar_get({args, 'freq_step'});
  [span, temp, results(7)]                   = utpar_get({args, 'span'});
  [amp, temp, results(8)]                    = utpar_get({args, 'amp'});
  [noise_power, temp, results(9)]            = utpar_get({args, 'noise_power'});
  [dc_power, temp, results(10)]              = utpar_get({args, 'dc_power'});
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
  n_inputs              = 3;
  n_bits_in             = 10;
  n_bits_out            = 18;

  %%%%%%%%%%%%%%%%%%%%
  % pfb_fir settings %   
  %%%%%%%%%%%%%%%%%%%%

  pfb_fir_model_name    = 'pfb_fir_generic_test';
  pfb_fir_block_name    = 'pfb_fir_generic';
  pfb_fir_type          = 'default';
  pfb_fir_block_version = '0'; 

  pfb_size              = fft_stages;
  pfb_n_bits_in         = n_bits_in;
  pfb_n_bits_out        = n_bits_out;
  pfb_coeff_bit_width   = 18;
  pfb_quantization      = 'Round  (unbiased: Even Values)';

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
  fft_overflow          = 'Wrap';

  %%%%%%%%%%%%%%%%%%%%%%
  % pfb_fir parameters %
  %%%%%%%%%%%%%%%%%%%%%%

  pfb_fir_parameters = { ...
      'TotalTaps', n_taps, ...
      'CoeffBitWidth', pfb_coeff_bit_width, ...
      'BitWidthIn', pfb_n_bits_in, ...
      'BitWidthOut', pfb_n_bits_out, ...
      'n_inputs', n_inputs, ...
      'PFBSize', fft_stages, ...
      'quantization', pfb_quantization, ...
  };

  pfb_fir_block = { ...
    'name', pfb_fir_block_name, ...
    'type', pfb_fir_type, ...
    'version', pfb_fir_block_version, ...
    'parameters', pfb_fir_parameters, ...
  }; %block

  [pfb_fir_model, result] = utpfb_fir_generic_bbox_modelify( ...
    'name', pfb_fir_model_name, ...
    'block', pfb_fir_block);
  if result ~= 0,
      utlog('error creating black box pfb_fir model', {'error', ut_log_group});
      return;
  end

  %erect the model if it doesn't already exist
  sys = find_system('type', 'block_diagram', 'name', pfb_fir_model_name);
  if isempty(sys),
    result = utmodel_erect(pfb_fir_model{:});
    if result ~= 0,
      utlog('error erecting pfb_fir model', {'error', ut_log_group});
      return;
    end
  else, %update if it exists
  %TODO should use utmodel_update

  end

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

    %generate data
    n_spectra = n_spectra+1;
    f = freq_index*fs;
    noise = noise_power*randn(1, 2^fft_stages*n_taps*n_spectra);
    dc = dc_power*ones(1, 2^fft_stages*n_taps*n_spectra);
    sinusoid = amp*sin(2*pi*f/(2^fft_stages)*[0:(2^fft_stages*n_taps*n_spectra)-1]);
    din = dc+noise+sinusoid;
%    din              = repmat([zeros(1,2^fft_stages*(n_taps-1)), 0.5.*ones(1,2^fft_stages)], 1, n_spectra);
    n_spectra = n_spectra-1;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % push data through pfb_fir %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    utlog('simulating pfb_fir response', {ut_log_group});
    [pfb_fir_dout, result] = utpfb_fir_generic_bbox_sim( pfb_fir_model{:}, ...
        'name', pfb_fir_block_name, 'din', din', 'debug', 'off');
    if result ~= 0,
      utlog('error black box simulating pfb_fir', {'error', ut_log_group});
      return;
    end 
   
    [r,c] = size(pfb_fir_dout);
    pfb_fir_dout = reshape(pfb_fir_dout, r*c, 1);
    pfb_fir_dout = pfb_fir_dout(1:2^fft_stages*n_spectra);
   
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % push data through fft %
    %%%%%%%%%%%%%%%%%%%%%%%%%
   
    utlog('simulating fft response', {ut_log_group});
    [fft_dout, result] = utfft_bbox_sim( fft_model{:}, ...
        'name', fft_block_name, 'fft_shift', fft_shift, 'din', pfb_fir_dout, 'debug', 'on');
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

  dout = response'; %flip so that column contains fft bin response 

  result = 0;

  if strcmp(plots, 'on'),
    %plot results
    figure;
    plot([offset:fs:(offset+span)-fs], 20*log10(dout));
    title('pfb chanel response');
  end
 
  utlog('exiting', {'trace', ut_log_group});
end %function
