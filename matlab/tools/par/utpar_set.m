% function[modified, result] = utpar_set(target, updates)
%
% For all names in updates, searches for them in target and updates the value
% to the one specified
%
% Variables that are not shared trigger a non match indication
% modified    = name, value pairs from target, replaced from updates
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

function[modified, result] = utpar_set(target, updates)

utlog(['entering utpar_set'], {'trace','utpar_set_debug'});

modified = [];
result = -1;

if ~isa(target,'cell'),
  utlog('target must be a cell array', {'error','utpar_set_debug'});
  return;
end
if ~isa(updates,'cell'),
  utlog('updates must be a cell array', {'error','utpar_set_debug'});
  return;
end

%no updates so leave as is
if length(updates) == 0,
  utlog(['nothing to update'], {'utpar_set_debug'});
  modified = target;
  result = 0;
  return;
end

temp = target{1};
if isempty(temp),
  return;
end

%find the base location
[base, base_index, result] = utpar_get(target);
if result ~= 0,
  utlog(['base array not found'], {'error', 'utpar_set_debug'});
  return;
else
  utlog(['base array found at position [',num2str(base_index),']'], {'utpar_set_debug'});
end

len = length(updates);

if len == 1, %value only
  utlog(['searching for location for single value'], {'utpar_set_debug'});
  
  value = updates{1};
  str = 'temp';
  %loop through index, drilling down through cell arrays
  for v_index = 1:length(base_index)-1,
  str = [str,'{',num2str(base_index(v_index)),'}'];
  end

  str_val = [str,'{',num2str(base_index(length(base_index))),'} = value;'];
  utlog([str_val], {'utpar_set_debug'});
  eval(str_val); 

else, %name, value pairs

  if mod(len,2) ~= 0,
    utlog('updates must be cell array of ''name'', ''value'' pairs',{'error', 'utpar_set_debug'});
    result = -1;
    return;
  end

  %run through updates
  for update_index = 1:2:len,
    location = updates{update_index};
    value = updates{update_index+1};

    if ~isa(location,'char') & ~isa(location,'cell'), %if name is not a valid location return error
      utlog(['updates needs ''name'' values in ''name'',''value'' pairs to be strings or cell arrays'], {'error','utpar_set_debug'});
      result = -1;
      return;
    end
    
    utlog(['searching for ',utto_string(location)], {'utpar_set_debug'});

    %try to find the parameter
    if isa(location,'char'),
      utlog(['string location'], {'utpar_set_debug'});
      coords = {base, location};
    else
      utlog(['cell array location'], {'utpar_set_debug'});
      coords = {base, location{:}};
    end
    [final, index_sub, result_sub] = utpar_get(coords);
    
    if (result_sub == 0),
      final_index = [base_index, index_sub];    
    else
      utlog([utto_string(location),' not found'], {'utpar_set_debug'});
      final_index = [];
    end

    %found parameter to replace
    if ~isempty(final_index),
      utlog([utto_string(location),' found at final index [',num2str(final_index),']'], {'utpar_set_debug'});

      %one could do this by having 2 loops, one drilling down copying cell arrays
      %as we go, modifying the value, then looping back out overwriting cell arrays 
      %as we go. All because Matlab cannot pass values by reference!
      
      str = 'temp';
      %loop through index, drilling down through cell arrays
      for v_index = 1:length(final_index)-1,
        str = [str,'{',num2str(final_index(v_index)),'}'];
      end

      str_val = [str,'{',num2str(final_index(length(final_index))),'} = value;'];
      utlog([str_val], {'utpar_set_debug'});
      eval(str_val); 
    else
      % report parameter not found if no other previous error
      if result == 0,
        result = 1;
      end
    end
  end %for index
end %if len

modified = temp;
utlog(['exiting utpar_set'], {'trace','utpar_set_debug'});
