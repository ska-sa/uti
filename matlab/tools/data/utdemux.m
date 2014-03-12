% Takes a single vector of data and parallelises in into columns 
%
% function [data] = utdemux(varargin)
%
% data            = resultant data in cell array, oldest data in lowest numbered cell
% varargin        = {'varname', value, ... } pairs. Valid values for varname are;
%   n_streams     = demux factor
%   complex       = whether input data is real or complex 
%   din           = the data to demux into parallel inputs 

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

function [data, result] = utdemux(varargin)
data = {}; result = -1;
log_group = 'utdemux_debug';

utlog('entering utdemux',{'trace', log_group});

defaults = { ...
  'n_streams', 4, ...
  'complex', 'on', ...            %generate separate real and imaginary inputs  
  'din', [0:7]', ...
}; %defaults

args    = {varargin{:}, 'defaults', defaults};
[n_streams, temp, results(1)]       = utpar_get({args, 'n_streams'});
[complex, temp, results(2)]         = utpar_get({args, 'complex'});
[din, temp, results(3)]             = utpar_get({args, 'din'});
if ~isempty(find(results ~= 0)),
  utlog(['error getting parameters'],{'error', log_group});
  return;
end

%check for weird input data dimensions
[rdin,cdin] = size(din);
utlog(['din has size rows = ',num2str(rdin),' cols = ',num2str(cdin)],{log_group});
if rdin ~= 1 && cdin ~= 1,
    utlog('number of rows or columns of input data must be 1',{'error', log_group});
    return
end

%ensure data is a column vector
if rdin == 1, 
    utlog(['rotating din'],{log_group});
    din = din';
    rdin = cdin;
    cdin = rdin; 
end

%quantise data to fit into multiple columns
din = din(1:floor(rdin/n_streams)*n_streams,1);

if strcmp(complex,'on'), %complex inputs have separate real and imaginary inputs 
  n_cols = n_streams*2;
else
  n_cols = n_streams;
end

%separate data into real and imaginary parts
if strcmp(complex, 'on'),
    din = [real(din), imag(din)];
    rdin = rdin*2;
end

%mush data into single column
din = reshape(din', rdin, 1);

%reshape data into different columns
din = reshape(din, n_cols, rdin/n_cols)';

%construct cell array of variables 
for idx = 1:n_cols,
    data{idx} = din(:,idx);
end %for

result = 0;

utlog('exiting utdemux',{'trace', log_group});
