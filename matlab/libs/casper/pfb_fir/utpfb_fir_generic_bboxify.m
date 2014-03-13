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

function [bbox, result] = utpfb_fir_generic_bboxify(varargin)
result = -1; bbox = {};
log_group = 'utpfb_fir_generic_bboxify_debug';

utlog('entering utpfb_fir_generic_bboxify',{'trace', log_group});

%if no block name passed use the default block and version
defaults = { ...
  'name', 'pfb_fir_generic', ...
  'type', 'default', ...
  'version', '0', ...
  'parameters', {}, ...  
}; %defaults

args = {varargin{:}, 'defaults', defaults};
[name, temp, results(1)]            = utpar_get({args, 'name'});
[version, temp, results(2)]         = utpar_get({args, 'version'});
[type, temp, results(3)]            = utpar_get({args, 'type'});
[parameters, temp, results(4)]      = utpar_get({args, 'parameters'});
if ~isempty(find(results ~= 0)),
  utlog('error getting parameters from varargin',{'error', log_group});
end

%%%%%%%%%%%%%%%
% parameters %
%%%%%%%%%%%%%%%

%do lookup based on type and version
if strcmp(type, 'default'),
    base = { ...
      'source', 'library', ...
      'location', 'casper_library_pfbs/pfb_fir_generic', ...
    };
  
  if strcmp(version, '0'),
    %default parameters
    default_params = { ...
        'n_streams', 1, ...
        'PFBSize', 5, ...
        'TotalTaps', 2, ...
        'WindowType', 'hamming', ...
        'n_inputs', 2, ...
        'BitWidthIn', 8, ...   %IEEE 754 double precision resolution uses 52 bits resolution and one sign bit
        'BitWidthOut', 18, ... 
        'CoeffBitWidth', 18, ...
        'complex', 'off', ...
        'async', 'off', ...
        'add_latency', 1, ...
        'mult_latency', 2, ...
        'bram_latency', 1, ...  
        'conv_latency', 2, ...  
        'fan_latency', 1, ...  
        'quantization', 'Round  (unbiased: Even Values)', ...
        'fwidth', 1, ...        
    }; %default params 

  else
    utlog(['Don''t know about pfb_fir_generic ',type, ' version ', version],{'error', log_group});
    return
  end %version  

else
  utlog(['Don''t know about pfb_fir_generic type ',type],{'error', log_group});
  return
end

%update parameters from those passed in
[final_params, results] = utpar_set({default_params}, parameters); 
if ~isempty(find(results ~= 0)),
  utlog('parameters passed in don''t match defaults',{'error', log_group});
  return;
end

%%%%%%%%%%%%%%%
% input ports %
%%%%%%%%%%%%%%%

if strcmp(type, 'default'),
  if strcmp(version, '0'),
    %get parameters influencing input ports
    [n_inputs, temp, results(1)]          = utpar_get({final_params, 'n_inputs'}); 
    [input_bit_width, temp, results(2)]   = utpar_get({final_params, 'BitWidthIn'}); 
    if ~isempty(find(results ~= 0)),
      utlog('error getting parameters used for input ports',{'error', log_group});
    end
   
    inputs = { ...
      {'synci', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'quantization', 'Truncate', 'overflow', 'Flag as error', 'bit_width', 1, 'bin_pt', 0}}, ...
      {'din', {'complex', 'off', 'parallelisation', 2^n_inputs, 'type', 'Signed', 'quantization', 'Round  (unbiased: +/- Inf)', 'overflow', 'Saturate', 'bit_width', input_bit_width, 'bin_pt', input_bit_width-1 }}, ...
      }; ... %inputs

  else,
    utlog(['Don''t know about block ',type, ' version ',version],{'error', log_group});
    return;
  end %version  

else,
  utlog(['Don''t know about block type ',type],{'error', log_group});
  return;
end %type

%%%%%%%%%%%%%%%%
% output ports %
%%%%%%%%%%%%%%%%

if strcmp(type, 'default'),
  if strcmp(version, '0'),
    %get parameters influencing output ports
    n_inputs          = utpar_get({final_params, 'n_inputs'}); 
    input_bit_width   = utpar_get({final_params, 'BitWidthIn'}); 
    output_bit_width  = utpar_get({final_params, 'BitWidthOut'}); 

    outputs = { ...
      {'synco', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'bit_width', 1, 'bin_pt', 0}}, ...
      {'dout', {'complex', 'off', 'parallelisation', 2^n_inputs, 'type', 'Signed', 'bit_width', output_bit_width, 'bin_pt', output_bit_width-1 }}
    }; ... %outputs
  else
    utlog(['Don''t know about block ',type, ' version ',version],{'error', log_group});
  end %version  

else
  utlog(['Don''t know about block type ',type],{'error', log_group});
end

bbox = { ...
  'block',   { 'name', name, base{:}, 'parameters', {final_params{:}}}, ...
  'inputs',  { 'ports', {inputs{:}}}, ...
  'outputs', { 'ports', {outputs{:}}}, ...
};

utlog('exiting utpfb_fir_generic_bboxify',{'trace',log_group});
result = 0;
