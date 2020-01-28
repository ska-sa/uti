% Takes in columns of data and muxes into single stream. If specified, data
% values can be combined into complex values. column length can be specified
%
% function[dout] = utmux(varargin)
% 
% dout          = single column of data
% varargin      = name, value pairs where name can be;
%   data        = data in columns as output from Simulink, oldest data in left-most columns
%   complex     = specifies if input data has real and imaginary components
%   vec         = column length

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   MeerKAT Radio Telescope Project (www.ska.ac.za)                           %
%   Andrew Martens                                                            %
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

function[dout, result] = utmux(varargin)
dout = []; result = -1;
log_group = 'utmux_debug';

utlog('entering utmux',{'trace', log_group});

defaults = { ...
  'data', [0 0 0 0 0 0; 0 1 2 3 4 5; 5 4 3 2 1 0; 6 7 8 9 10 11]', ...
  'cplx', 'on' ...
  'vec_len', 0
}; %data is complex so 3 complex values per frame

args = {varargin{:}, 'defaults', defaults};
[data, temp, results(1)]        = utpar_get({args, 'data'});
[cplx, temp, results(2)]        = utpar_get({args, 'cplx'});
[vec_len, temp, results(3)]     = utpar_get({args, 'vec_len'});
if ~isempty(find(results ~= 0)),
  utlog(['error getting parameters'],{'error', log_group});
  return;
end

[r,c] = size(data);
if strcmp(cplx, 'on') && mod(c,2) ~= 0,
    utlog('need even number of columns for complex data',{'error', log_group});
    return
end

utlog(['processing data of dimensions ',num2str(r),' rows, ',num2str(c),' columns'],{log_group});

if strcmp(cplx, 'on'), 
    utlog('processing complex data',{log_group});
    cols = 2;
else, cols = 1;
end

%convert to 1 (or 2 for complex) columns
data = reshape(reshape(data', r*c, 1), cols, (r*c)/cols)'; 

% complexify data if required
if strcmp(cplx,'on'),
    data = complex(data(:,1), data(:,2));
    utlog(['converting into complex column'],{log_group});
end

%cut off fractions of spectrum and create columns
if vec_len > 0,
    [r,c] = size(data);
    vecs = floor(r*c/vec_len);
    data = reshape(data(1:vecs*vec_len,:), vec_len, vecs);
end

utlog('exiting utmux',{'trace', log_group});

dout = data;
result = 0;
