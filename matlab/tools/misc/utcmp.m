% function[result] = utcmp(a, b)
%
% Compares a and b
% result = -1 - different type 
% result = 0  - same type, different value or size
% result = 1  - same type, same value

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

function[result] = utcmp(a, b)
result = -1;
log_group = 'utcmp_debug';
utlog('entering', {'trace', log_group}); 

%we can't compare variables of different types
if ~strcmp(class(a), class(b)),
  return;
end

%at this point we know the types are the same 

%if numerical find any differences
if strcmp(class(a), 'double'),
 
  %if different length arrays classify as same type but not same value 
  if length(a) ~= length(b),
    result = 0;
  else
    result = isempty(~find(a ~= b));
  end
  utlog(['doubles found: a = ',num2str(a),' b = ',num2str(b),' result = ',num2str(result)],{log_group});
  return;

%if string
elseif strcmp(class(a), 'char'),

  %if both numbers then convert and compare as numbers
  a_num = str2num(a);
  b_num = str2num(b);
  if(a_num ~= NaN & b_num ~= NaN),
    if length(a_num) == length(b_num),
      result = isempty(~find(a_num ~= b_num));
    else
      result = 0;
    end
    utlog(['string containing doubles: a = ',num2str(a_num),' b = ',num2str(b_num),' result = ',num2str(result)],{log_group});
    return;
  else, %otherwise compare as strings
    result = strcmp(a,b);
    utlog(['string: a = ',a,' b = ',b,' result = ',num2str(result)],{log_group});
  end

% %if cell array
% elseif strcmp(class(a), 'cell'),
%   result = 1; %optimist
%   
%   %compare if same length
%   if length(a) == length(b),  
%     %loop through cell array comparing each variable in turn
%     for index = 1:length(a),
%       temp_result = utcmp(a{index}, b{index});
%       %exit as soon as types or lengths are different
%       if temp_result == -1,
%         result = -1;
%         break;
%       else, 
%         %if everything good update with latest result
%         if result == 1,
%           result = temp_result;
%         %otherwise remember that at least one variable did not match
%         %but continue comparing as may get type or length problem
%         else,         
%         end
%       end
%     end
%   else %different length cell arrays don't match in a bad way
%     result = -1;
%     return;
%   end

else,
  disp(['Do not know how to compare ',class(a),' with ',class(b),]);
  utlog(['Do not know how to compare ',class(a),' with ',class(b)],{'error', log_group});
end

utlog('exiting', {'trace', log_group}); 
