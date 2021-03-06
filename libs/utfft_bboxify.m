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

%returns parameters and port descriptions to construct bbox simulation model
%TODO split this up

function [bbox, result] = utfft_bboxify(varargin)
result = -1; bbox = {};
log_group = 'utfft_bboxify_debug';

utlog('entering utfft_bboxify',{'trace', log_group});

%if no block name passed use the default block and version
defaults = { ...
  'name', 'fft_wideband_real', ...
  'type', 'fft_wideband_real', ...
  'version', '2', ... %most recent version
  'parameters', {}, ...  
}; %defaults

args = {varargin{:}, 'defaults', defaults};
[block_name, temp, results(1)]            = utpar_get({args, 'name'});
[block_version, temp, results(2)]         = utpar_get({args, 'version'});
[block_type, temp, results(3)]            = utpar_get({args, 'type'});
[block_parameters, temp, results(4)]      = utpar_get({args, 'parameters'});
if ~isempty(find(results ~= 0)),
  utlog('error getting parameters from varargin',{'error', log_group});
end

%%%%%%%%%%%%%%
% parameters %
%%%%%%%%%%%%%%

%do lookup based on type and version
%TODO other fft types
if strcmp(block_type, 'fft_wideband_real'),
    base = { ...
      'block_type', block_type, ...
      'version', num2str(block_version), ...
      'source', 'library', ...
      'location', 'casper_library_ffts/fft_wideband_real', ...
    };
 
  if strcmp(block_version, '0'),
    default_params = { ...
        'FFTSize', 5, ...
        'n_inputs', 2, ...
        'input_bit_width', 18, ...
        'coeff_bit_width', 18,  ...
        'add_latency', 1, ...
        'mult_latency', 2, ...
        'bram_latency', 2, ...
        'conv_latency', 1, ...
        'input_latency', 0, ...
        'biplex_direct_latency', 0, ...
        'quantization', 'Round  (unbiased: +/- Inf)', ...
        'overflow', 'Saturate', ...
        'arch', 'Virtex5', ...
        'opt_target', 'logic', ...
        'coeffs_bit_limit', 8, ...
        'delays_bit_limit', 8, ...
        'mult_spec', 2, ...
        'hardcode_shifts', 'off', ...
        'shift_schedule', [1 1 1 1 1], ...
        'dsp48_adders', 'off', ...
        'unscramble', 'on', ...
    }; %default params
 
  elseif strcmp(block_version, '1'), 
    default_params = { ...
        'n_streams', 1, ...
        'FFTSize', 5, ...
        'n_inputs', 2, ...
        'input_bit_width', 18, ...
        'bin_pt_in', 17, ...
        'coeff_bit_width', 18,  ...
        'unscramble', 'on', ...
        'async', 'off', ...
        'add_latency', 1, ...
        'mult_latency', 2, ...
        'bram_latency', 2, ...
        'conv_latency', 1, ...
        'input_latency', 0, ...
        'biplex_direct_latency', 0, ...
        'quantization', 'Round  (unbiased: +/- Inf)', ...
        'overflow', 'Saturate', ...
        'delays_bit_limit', 8, ...
        'coeffs_bit_limit', 8, ...
        'coeff_sharing', 'on', ...
        'coeff_decimation', 'on', ...
        'coeff_generation', 'on', ...
        'cal_bits', 1, ...
        'n_bits_rotation', 25, ...
        'mult_spec', 2, ...
        'max_fanout', 4, ... 
        'bitgrowth', 'off', ...
        'max_bits', 19, ...
        'hardcode_shifts', 'off', ...
        'shift_schedule', [1 1 1 1 1], ...
        'dsp48_adders', 'off', ...
    }; %default params 

  elseif strcmp(block_version, '2'), 
    default_params = { ...
	'n_streams', 1, ...
	'FFTSize', 6, ...
	'n_inputs', 2, ...
	'input_bit_width', 18, ...
	'bin_pt_in', 17, ...
	'coeff_bit_width', 18,  ...
	'floating_point', 'off', ...
	'float_type', 'single', ...
	'exp_width', 8, ...
	'frac_width', 24, ...
	'async', 'off', ...
	'unscramble', 'on', ...
	'add_latency', 1, ...
	'mult_latency', 2, ...
	'bram_latency', 2, ...
	'conv_latency', 0, ...
	'input_latency', 0, ...
	'add_pipe_latency', 0, ...
	'mult_pipe_latency', 0, ...
	'biplex_direct_latency', 0, ...
	'quantization', 'Round  (unbiased: +/- Inf)', ...
	'overflow', 'Saturate', ...
	'delays_bit_limit', 8, ...
	'coeffs_bit_limit', 8, ...
	'coeff_sharing', 'on', ...
	'coeff_decimation', 'on', ...
	'coeff_generation', 'on', ...
	'cal_bits', 1, ...
	'n_bits_rotation', 25, ...
	'max_fanout', 4, ...   
	'mult_spec', 2, ...
	'bitgrowth', 'off', ...
	'max_bits', 19, ...
	'hardcode_shifts', 'off', ...
	'shift_schedule', [1 1 1 1 1], ...
	'dsp48_adders', 'off', ...
    }; %default_params

  else,
    utlog(['Don''t know about fft ', block_type, ' version ', block_version], {'error', log_group});
    return
  end %block_version  

else,
  utlog(['Don''t know about fft type ', block_type], {'error', log_group});
  return
end

%update parameters from those passed in
[final_params, results] = utpar_set({default_params}, block_parameters);
if ~isempty(find(results ~= 0)),
  utlog('parameters passed in don''t match defaults', {'error', log_group});
  return;
end

%%%%%%%%%%%%%%%
% input ports %
%%%%%%%%%%%%%%%

if strcmp(block_type, 'fft_wideband_real'),
  %get parameters influencing input ports
  [n_inputs, temp, results(1)]          = utpar_get({final_params, 'n_inputs'});
  [input_bit_width, temp, results(2)]   = utpar_get({final_params, 'input_bit_width'}); 
  [fft_size, temp, results(3)]          = utpar_get({final_params, 'FFTSize'});
  if ~isempty(find(results ~= 0)),
    utlog('error getting parameters used for input ports',{'error', log_group});
  end
  
  inputs = { ...
  {'synci', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'quantization', 'Truncate', 'overflow', 'Flag as error', 'bit_width', 1, 'bin_pt', 0}}, ...
  {'shift', {'complex', 'off', 'parallelisation', 1, 'type', 'Unsigned', 'quantization', 'Truncate', 'overflow', 'Wrap', 'bit_width', fft_size, 'bin_pt', 0}}, ...
  }; ... %inputs

  din_params = {'complex', 'off', 'parallelisation', 2^n_inputs, 'type', 'Signed', 'quantization', 'Round  (unbiased: +/- Inf)', 'overflow', 'Saturate', 'bit_width', input_bit_width, 'bin_pt', input_bit_width-1 };

  if strcmp(block_version, '0'),
    inputs = { ...
      inputs{:}, ...
      {'din', din_params}, ...
      }; ... %inputs
  elseif strcmp(block_version, '1') || strcmp(block_version, '2'),
    
    %get parameters influencing input ports
    [n_streams, temp, results(1)]          = utpar_get({final_params, 'n_streams'});
    if ~isempty(find(results ~= 0)),
      utlog('error getting parameters used for input ports',{'error', log_group});
    end
  
    %we need a separate data input for every stream
    for n = 0:n_streams-1,
      inputs = { ...
	inputs{:}, ...
        {['din',num2str(n)], din_params}, ...
      }; ... %inputs
    end %for
    
  else,   
    utlog(['Don''t know about fft type ', block_type, ' block version ', num2str(block_version)], {'error', log_group});
    return;
  end %version  

else,
  utlog(['Don''t know about fft type ', block_type], {'error', log_group});
  return;
end %type

%%%%%%%%%%%%%%%%
% output ports %
%%%%%%%%%%%%%%%%

if strcmp(block_type, 'fft_wideband_real'),
    %get parameters influencing output ports
    n_inputs          = utpar_get({final_params, 'n_inputs'}); 
    input_bit_width   = utpar_get({final_params, 'input_bit_width'}); 

    outputs = {{'synco', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'bit_width', 1, 'bin_pt', 0}}};
    dout_params = {'complex', 'on', 'parallelisation', 2^(n_inputs-1), 'type', 'Signed', 'bit_width', input_bit_width, 'bin_pt', input_bit_width-1};

  if strcmp(block_version, '0'), 
    n_streams = 1;
  elseif strcmp(block_version, '1') || strcmp(block_version, '2'),
    %get parameters influencing input ports
    [n_streams, temp, results(1)]          = utpar_get({final_params, 'n_streams'});
    if ~isempty(find(results ~= 0)),
      utlog('error getting parameters used for input ports',{'error', log_group});
    end

  else
    utlog(['Don''t know about fft ', block_type, ' version ', block_version],{'error', 'utfft_bboxify_debug'});
  end %version  
    
  for n = 0:n_streams-1,
    outputs = { ...
      outputs{:}, ...
      {['dout',num2str(n)], dout_params}, ...
    }; %outputs
  end %for

  outputs = { ...
    outputs{:}, ...
    {'of', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'bit_width', 1, 'bin_pt', 0}}, ...
  }; ... %outputs

else
  utlog(['Don''t know about fft type ', block_type],{'error', log_group});
end

%combine block with input and output ports

bbox = { ...
  'block',   { 'name', block_name, base{:}, 'parameters', {final_params{:}}}, ...
  'inputs',  { 'ports', {inputs{:}}}, ...
  'outputs', { 'ports', {outputs{:}}}, ...
};

utlog('exiting utfft_bboxify',{ 'trace', log_group});
result = 0;

end %function
