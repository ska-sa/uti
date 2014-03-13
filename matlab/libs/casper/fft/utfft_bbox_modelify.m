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

%creates bbox model of fft for passing to model_erect etc from block created with utfft_blockify
%TODO investigate generic bboxify function taking block name and callbacks 
function[model, result] = utfft_bbox_modelify(varargin)
model = {}; result = -1;
log_group = 'utfft_bbox_modelify';

utlog('entering utfft_bbox_modelify',{'trace', log_group});

defaults = { ...
  'name', 'fft_test', ...
  'block', { ...
    'name', 'fft_wideband_real', ...
    'type', 'fft_wideband_real', ...  
    'version', '0', ...
    'parameters', { ...
      'n_inputs', 2, ...
      'FFTSize', 6, ...
    }, ...%parameters
  }, ... %block
}; %defaults

args = {varargin{:}, 'defaults', defaults};
[name, temp, results(1)]      = utpar_get({args, 'name'});
[block, temp, results(2)]     = utpar_get({args, 'block'});
if ~isempty(find(results ~= 0)),
  utlog('error getting parameters from varargin',{'error', log_group});
  return;
end

%get stuff to construct black box based on name and version
[bbox, result] = utfft_bboxify(block{:});
if result ~= 0,
  utlog('error getting black box',{'error', log_group});
  return;
end

[model, result] = utbbox_modelify('name', name, 'bbox', bbox);
if result ~= 0,
  utlog('error creating model from black box',{'error', log_group});
  return;
end

utlog('exiting utfft_bbox_modelify',{'trace', log_group});
