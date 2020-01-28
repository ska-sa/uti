% function[enlarged, result] = utpar_insert(items, target)
%
% Inserts parameters from varargin0 into varargin1
%
% Variables that are not shared trigger a non match indication
% enlarged    = name, value pairs from varargin0, with inserts from varargin1
% result      = 0 if all variables were found and replaced, 1 if some were not found, -1 error

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

function[enlarged, result] = utpar_insert(items, target)

utlog(['entering utpar_insert'], {'trace','utpar_insert_debug'});
enlarged = {};
result = -1;

if mod(length(items),2) ~= 0,
  utlog(['items must consist of ''name'',value pairs'], {'error','utpar_insert_debug'});
  error('items must consist of ''name'',value pairs');
end

%find base array
if ~isa(target,'cell'),
  utlog('target must be a cell array', {'error','utpar_insert_debug'});
  return;
end

%find the base location
[base, base_index, result] = utpar_get(target);
utlog(['base array found at position [',num2str(base_index),']'], {'utpar_insert_debug'});

if result ~= 0,
  utlog(['error finding location in target'], {'error','utpar_insert_debug'});
  return;
end

%run through items
for index = 1:2:length(items),
  location = items{index};
  value = items{index+1};

  if isa(location,'char'), %is a name, so insert into base
    name = location;
    utlog(['directly adding ',name,' to base array'], {'utpar_insert_debug'});
  else,
    utlog(['location info must be a string'], {'error','utpar_insert_debug'});
  end

  if ~isa(name,'char'),
    utlog(['parameter names to be inserted must be strings'], {'error','utpar_insert_debug'});
    result = -1;
    return;
  end  

  utlog(['inserting ',name], {'utpar_insert_debug'});

  len = length(base);
  base{len+1} = name;
  base{len+2} = value; 
end %for index 

enlarged = target{1};
%insert array back into parameter list
str = 'enlarged';
for array_index = 1:length(base_index),
  str = [str,'{',num2str(base_index(array_index)),'}'];
end

str = [str,' = base;'];
utlog(str, {'utpar_insert_debug'});
eval(str);

result = 0;
utlog(['exiting utpar_insert'], {'trace','utpar_insert_debug'});
