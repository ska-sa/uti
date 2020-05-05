%generate single and dual-stream CASPER fft_wideband_real, push data through, return results.
%varargout = 'single' <single stream FFT outputs> 'dual0/1' <dual stream FFT output0/1> 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   SKA Africa                                                                %
%   http://www.kat.ac.za                                                      %
%   Copyright (C) 2020 SARAO                                                  %
%   Author: Andrew Martens(andrew@ska.ac.za)                                  %
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

function[varargout, result] = casper_fft_wideband_real_single_vs_dual_stream(varargin)
  clear all;
 
  mfilename('class') 
  ut_debug_group = [mfilename('class'),'_debug'];
  result = -1; 
  varargout = {}; 
  ut_log_groups = {'error', ut_debug_group};

  block_name = 'fft_wideband_real';
  type = block_name;
  block_version = '2'; %basically parameter options

  %%%%%%%%%%%%%%%%%%%%%
  % system parameters %
  %%%%%%%%%%%%%%%%%%%%%

  plots = 1; %plots showing various stuff at end
  n_spectra = 1;
  fft_stages = 16;
  fft_shift = (2^fft_stages)-1;

  %%%%%%%%%%%%%%%%%%%%
  % block parameters %
  %%%%%%%%%%%%%%%%%%%%
  
  %these parameters are identical 
  shared_params = { ...
      'coeff_bit_width', 22, ...
      'input_bit_width', 22, ...
      'bin_pt_in', 21, ...
      'n_inputs', 3, ...
      'FFTSize', fft_stages, ...
      'quantization', 'Round  (unbiased: Even Values)', ...
      'overflow', 'Wrap', ...
      'delays_bit_limit', 8, ...
      'coeffs_bit_limit', 13, ...
      'coeff_decimation', 'on', ...
      'coeff_sharing', 'on', ...
      'coeff_generation', 'on', ...
      'cal_bits', 11, ...
      'max_fanout', 1, ...
  };
 
  %only the number of streams differ 

  single_stream_model_name = 'single_stream_fft_test';
  single_stream_params = { ...
      'n_streams', 1, ...
      shared_params{:};
  };
  
  dual_stream_model_name = 'dual_stream_fft_test';
  dual_stream_params = { ...
      'n_streams', 2, ...
      shared_params{:};
  };

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % construct black box model for erecting %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  single_stream_block = { ...
    'name', block_name, ...
    'type', type, ...
    'version', block_version, ...
    'parameters', single_stream_params, ...
  }; %block

  [single_stream_model, result] = utfft_bbox_modelify( ...
    'name', single_stream_model_name, ...
    'block', single_stream_block);
  if result ~= 0,
      utlog('error creating single stream black box fft model', {'error', ut_debug_group});
      return;
  end
  
  dual_stream_block = { ...
    'name', block_name, ...
    'type', type, ...
    'version', block_version, ...
    'parameters', dual_stream_params, ...
  }; %block

  [dual_stream_model, result] = utfft_bbox_modelify( ...
    'name', dual_stream_model_name, ...
    'block', dual_stream_block);
  if result ~= 0,
      utlog('error creating dual stream black box fft model', {'error', ut_debug_group});
      return;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % erect the models if they don't already exist %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  single_sys = find_system('type', 'block_diagram', 'name', single_stream_model_name);
  if isempty(single_sys),
    result = utmodel_erect(single_stream_model{:});
    if result ~= 0,
      utlog('error erecting single stream model', {'error', ut_debug_group});
      return;
    end
  else, %update if exists
  %TODO should use utmodel_update
  end
  
  dual_sys = find_system('type', 'block_diagram', 'name', dual_stream_model_name);
  if isempty(dual_sys),
    result = utmodel_erect(dual_stream_model{:});
    if result ~= 0,
      utlog('error erecting single stream model', {'error', ut_debug_group});
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
     'impulse', { ...
      'offset', 3, ...
      'amplitude', 0.5, ...
      'type', 'periodic', ...
      'period', 2^fft_stages, ...
    }, ...
%    'sinusoid', { ...
%      'cycles', 500, ...
%      'amplitude', 0.25, ...
%      'period', 2^fft_stages, ...
%      'phase_offset', 0, ...
%    }, ...
  };

  [din, result] = utdata_gen('sources', sources, 'vec_len', n_spectra*2^fft_stages);

  if result ~= 0,
    utlog('error generating simulation input data', {'error', ut_debug_group});
    error('error generating simulation input data');
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % simulate single stream fft %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  [dout, result] = utfft_bbox_sim(single_stream_model{:}, ...
      'name', block_name, 'fft_shift', fft_shift, 'din0', din);
  if result ~= 0,
    utlog('error black box simulating single stream fft', {'error', ut_debug_group});
    return;
  end 

  [dout0, temp, result] = utpar_get({dout, 'dout0'});
  if(result ~= 0),
    utlog('can''t find data0 in dout from single stream fft_bbox_sim', {'error', ut_debug_group});
    error('can''t find data0 in dout from single stream fft_bbox_sim');
  end

  [r,c] = size(dout0);
  %pick out results due to our test inputs
  if c >= n_spectra,  
    single = dout0(1:2^(fft_stages-1),1:n_spectra);
  else,
    utlog(['error extracting ',num2str(n_spectra),' spectra from single stream data dout0, ',num2str(c),' found'], {'error', ut_debug_group});
  end
  
  varargout = {'single', single};  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % simulate dual stream fft %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%

  [dout, result] = utfft_bbox_sim(dual_stream_model{:}, ...
      'name', block_name, 'fft_shift', fft_shift, 'din0', din, 'din1', din);
  if result ~= 0,
    utlog('error black box simulating dual stream fft', {'error', ut_debug_group});
    return;
  end 

  dual = repmat({zeros(2^(fft_stages-1),n_spectra)}, 1, 2);
  for stream_idx = 0:2-1.
    stream_name = ['dout',num2str(stream_idx)];
    [d, temp, result] = utpar_get({dout, stream_name});
    if(result ~= 0),
      utlog('can''t find ',stream_name,' in dout from multi stream fft_bbox_sim', {'error', ut_debug_group});
    end

    [r,c] = size(d);
    %pick out results due to our test inputs
    if c >= n_spectra,  
      data = d(:,1:n_spectra);
    else,
      utlog(['error extracting ',num2str(n_spectra),' spectra from multi stream output ',stream_name,'.',num2str(c),' found'], {'error', ut_debug_group});
    end

    varargout = {varargout{:}, ['dual',num2str(stream_idx)], data};
    dual{stream_idx+1} = data;
  end %for

  if plots,
    s_vs_d0 = single - dual{1};
    s_vs_d1 = single - dual{2};
    d0_vs_d1 = dual{1} - dual{2};
    plot(real(s_vs_d0));
    title('Single stream - Dual Stream 0');
    hold on;
    plot(imag(s_vs_d0));
    figure;
    plot(real(s_vs_d1));
    title('Single stream - Dual Stream 1');
    hold on;
    plot(imag(s_vs_d1));
    figure;
    plot(real(d0_vs_d1));
    title('Dual Stream 0 - Dual Stream 1');
    hold on;
    plot(imag(d0_vs_d1));
  end %if plots

end %function
