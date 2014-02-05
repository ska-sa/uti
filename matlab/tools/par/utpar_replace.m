% function[varout, result] = utpar_replace(varargin0, varargin1)
%
% For all names in varargin1, searches for them in varargin0 and replaces them with
% the specified name, value pair
%
% Variables that are not shared trigger a non match indication
% varout      = name, value pairs from varargin0, replaced from varargin1
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

function[replaced, result] = utpar_replace(target, items)

utlog(['entering utpar_replace'], {'trace','utpar_replace_debug'});

replaced = target;
result = -1;

if ~isa(target,'cell')
  utlog(['target must be a cell array'], {'error','utpar_replace_debug'});
end
if ~isa(items,'cell')
  utlog(['items must be a cell array'], {'error','utpar_replace_debug'});
end

if mod(length(items),2) ~= 0,
  utlog(['items must consist of ''location'',{''new name'', ''new value''} pairs'], {'error','utpar_replace_debug'});
  error('items must consist of ''location'',{''new name'', ''new value''} pairs');
end

%find the base array

[base, base_index, result] = utpar_get(target);
utlog(['base array found at position [',num2str(base_index),']'], {'utpar_replace_debug'});

if result ~= 0,
  utlog(['error finding base location in target'], {'error','utpar_replace_debug'});
  return;
end

if ~isa(base,'cell'),
  utlog(['base location specified in target is not a cell array'], {'error','utpar_replace_debug'});
  return;
end

result = 0;
%run through items
for index = 1:2:length(items),
  location = items{index};
  item = items{index+1};
  
  if ~isa(item,'cell') | length(item) ~= 2, %if item is not as expected
    utlog(['items needs ''value'' values in ''name'',''value'' pairs to be cell arrays of form {''name'',value}'], {'error','utpar_replace_debug'});
    result = -1;
    return;
  end

  new_name = item{1};
  if ~isa(new_name,'char'), %if new_name is not a string return error
    utlog(['items needs ''name'' values in value part of ''name'',''value'' pairs to be strings'], {'error','utpar_replace_debug'});
    result = -1;
    return;
  end

  if ~isa(location,'char'), %if name is not a string return error
    utlog(['items needs ''name'' values in ''name'',''value'' pairs to be strings'], {'error','utpar_replace_debug'});
    result = -1;
    return;
  end
  
  utlog(['searching for ',location,' to be replaced with ',new_name], {'utpar_replace_debug'});

  %try to find the parameter
  [val, target_index, result] = utpar_get({base, location});
  
  %found parameter to replace
  if result == 0,
    utlog([location,' found at index ',num2str(target_index)], {'utpar_replace_debug'});

    base{target_index-1} = item{1}; %name
    base{target_index} = item{2};   %value
  else,
    if result == 0,
      result = 1;
    end  
  end
end %for index

replaced = target{1};
str = 'replaced';
%loop through index, drilling down through cell arrays
for v_index = 1:length(base_index),
  str = [str,'{',num2str(base_index(v_index)),'}'];
end
str = [str,' = base;']; 
utlog([str], {'utpar_replace_debug'});

eval(str);
utlog(['exiting utpar_replace'], {'trace','utpar_replace_debug'});
