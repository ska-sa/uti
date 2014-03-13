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

%function to compare basic results of matlab fft vs casper fft_wideband_real
function[data, data_ref, result] = casper_vs_matlab_basic(varargin)
  clear all;
  
  ut_debug_group = 'casper_vs_matlab_basic_debug';
  result = -1; 
  data = []; 
  data_ref = [];
  ut_log_groups = {'error', ut_debug_group};
  model_name = 'fft_test';
  block_name = 'fft_wideband_real';
  type = block_name;
  block_version = '1';

  %%%%%%%%%%%%%%%%%%%%
  % block parameters %
  %%%%%%%%%%%%%%%%%%%%
   
  n_inputs = 3;
  fft_stages = 13;
  input_bit_width = 18;
  coeff_bit_width = 18;
  quantization = 'Round  (unbiased: Even Values)';
  overflow = 'Wrap';
  mult_spec = 2;
  cal_bits = 1;

  parameters = { ...
      'coeff_bit_width', coeff_bit_width, ...
      'input_bit_width', input_bit_width, ...
      'bin_pt_in', input_bit_width-1, ...
      'n_inputs', n_inputs, ...
      'FFTSize', fft_stages, ...
      'quantization', quantization, ...
      'overflow', overflow, ...
      'mult_spec', mult_spec, ...
      'cal_bits', cal_bits, ...
  };

  %%%%%%%%%%%%%%%%%%%%%
  % system parameters %
  %%%%%%%%%%%%%%%%%%%%%

  fft_shift  = 2^fft_stages-1;

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %construct black box model for erecting
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  block = { ...
    'name', block_name, ...
    'type', type, ...
    'version', block_version, ...
    'parameters', parameters, ...
  }; %block

  [model, result] = utfft_bbox_modelify( ...
    'name', model_name, ...
    'block', block);
  if result ~= 0,
      utlog('error creating black box fft model', {'error', ut_debug_group});
      return;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % erect the model if it doesn't already exist %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  sys = find_system('type', 'block_diagram', 'name', model_name);
  if isempty(sys),
    result = utmodel_erect(model{:});
    if result ~= 0,
      utlog('error erecting model', {'error', ut_debug_group});
      return;
    end
  else, %update if exists
  %TODO should use utmodel_update

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % simulation data input settings %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %%%%%%%%%%%%%%%%%%%
  % raw data inputs %
  %%%%%%%%%%%%%%%%%%%

  sources = { ...
    'noise', { ...
      'power', 1/2^9, ...
      'mean', 0, ...
      'random', 'off', ...
      'seed', 0, ...
    }, ...
    'sinusoid', { ...
      'cycles', 500, ...
      'amplitude', 0.25, ...
      'period', 2^fft_stages, ...
      'phase_offset', 0, ...
    }, ...

%    'impulse', { ...
%      'offset', 3, ...
%      'amplitude', 0.5, ...
%      'type', 'periodic', ...
%      'period', 2^fft_stages, ...
%    }, ...
  };
  n_spectra = 1024;

  [din, result] = utdata_gen('sources', sources, 'vec_len', n_spectra*2^fft_stages);

  if result ~= 0,
    utlog('error generating simulation input data', {'error', ut_debug_group});
    error('error generating simulation input data');
  end
  
  %%%%%%%%%%%%
  % simulate %
  %%%%%%%%%%%%

  [data, result] = utfft_bbox_sim(model{:}, ...
      'name', block_name, 'fft_shift', fft_shift, 'din', din, 'debug', 'on');
  if result ~= 0,
    utlog('error black box simulating fft', {'error', ut_debug_group});
    return;
  end 
 
  %pick out results due to our test inputs
  [r,c] = size(data);
  if c >= n_spectra,  
    data = data(1:2^(fft_stages-1),1:n_spectra);
  else,
    utlog(['error extracting ', num2str(n_spectra), 'from data, ',num2str(c),' found'], {'error', ut_debug_group});
  end
  %calculate ideal result for our fft
  [data_ref, result] = utfft_sim( ...
      'din', din, ...
      'type', 'fft_wideband_real', ...
      'version', '0', ...
      'system_parameters', { ...
          'shift_schedule', fft_shift, ...
      }, ...
      'block_parameters', { ...             %parameters used to create FFT
          parameters{:}, ...
      }, ... %block_parameters
      'sim_settings', { ...
          'quantise_input', 'on', ...     %quantise input data before fft'ing
          'shift', 'on', ...              %simulate impact of shift schedule
      }); %utfft_sim

  result = 0;

end %function
