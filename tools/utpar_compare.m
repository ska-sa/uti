% function[result, comparison] = utpar_compare(values, target)
%
% Compares items in values against target
% Variables that are not shared trigger a non match indication
% comparison  = name, value pairs for all parameters in values
%   name      = variable name 
%   value     = -1 not found or different type, 0 same type but not same value or size, 1 same type and value 

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

function[aggregate, comparison, result] = utpar_compare(values, target)

result = -1; comparison = {};
aggregate = -1;
utlog('entering utpar_compare',{'trace', 'utpar_compare_debug'});

%sanity checking
if mod(length(values),2) ~= 0,
  utlog('values must contain ''name'', ''value'' pairs',{'error','utpar_compare_debug'});
  return;
end

if ~isa(target, 'cell'),
  utlog('target must be a cell array',{'error','utpar_compare_debug'});
  return;
end

%find the base location
[base, base_index, result] = utpar_get(target);
utlog(['base array found at position [',num2str(base_index),']'], {'utpar_compare_debug'});

if result ~= 0,
  utlog(['error finding base location in target'], {'error','utpar_compare_debug'});
  return;
end

aggregate = 1;

% loop through values to compare 
for index0 = 1:2:length(values),
  var_location = values{index0};
  var_val0 = values{index0+1};

  if ~isa(var_location,'char'),
    utlog(['Did not find a string for variable name in values at position ',num2str(index0*2+1),' as expected'],{'error','utpar_compare_debug'});
    aggregate = -1;
    return;
  end
 
  %try to find variable in target
  [var_val1, index, result] = utpar_get({base,var_location});
  
  %if we found it
  if result == 0,
    %if have cell arrays, then compare those
    %comparison will get aggregate comparison 
    if (isa(var_val0,'cell') && isa(var_val1,'cell')),
      [temp_result, temp_vars, var_cmp] = utpar_compare(var_val0, var_val1);
      if temp_result ~= 0, %error triggers mismatch label
        aggregate = -1;
      end

    else, %otherwise compare
      %if found something
      var_cmp = utcmp(var_val0, var_val1);
      utlog([var_location,' found, comparison = ',num2str(var_cmp)],{'utpar_compare_debug'});
    end

    if aggregate == 1,% if everything still matching, then update from latest result
      aggregate = var_cmp;
    elseif aggregate == 0,  %if type match but values not the same
      if var_cmp == -1;     %update only if error or type mismatch
        aggregate = var_cmp;
      end
    end %if aggregate 
  else
    utlog([var_location,' not found'],{'utpar_compare_debug'});
    var_cmp = -1;
    aggregate = -1;
  end

  %insert info into comparison 
  comparison{index0} = var_location;
  comparison{index0+1} = var_cmp; 
end %for

result = 0;
utlog('exiting utpar_compare',{'trace', 'utpar_compare_debug'});
