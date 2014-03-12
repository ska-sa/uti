%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   SKA Africa                                                                %
%   http://ska.ac.za                                                          %
%   Copyright (C) 2014 Andrew Martens                                         %
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

function[output, result] = utto_string(var)

log_group = 'utto_string_debug';
utlog('entering', {log_group, 'trace'});

result = -1;
output = '';
if isempty(var),
  result = 0;
  return;
end
% if a cell array then iteratively convert 
if isa(var, 'cell'),
  [r,c] = size(var);
  output = cell(r,c);
  for row_index = 1:r,
    for col_index = 1:c,
      [output{row_index,col_index}, result] = utto_string(var{row_index,col_index});
      if result == -1,
        return;
      end
    end
  end
elseif isa(var, 'numeric'),
  output = mat2str(var);
  result = 0;
elseif isa(var, 'char'),
  output = var;
  result = 0;
else
  utlog(['don''t know how to convert variable of class ',class(var),' to string'], {'error', log_group});
end

utlog('exiting', {log_group, 'trace'});
