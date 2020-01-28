% Find the index and value of the first instance of varname in varargin.  If varname is 
% not found, looks for 'defaults' and tries to find varname in there.  
%
% function value = utpar_get({varargin, varname})
%
% varname = the variable name to retrieve (as a string).
% varargin = {'varname', value, ...} pairs

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


function [value, index, result] = utpar_get(target)

utlog('entering utpar_get',{'trace', 'utpar_get_debug'});

result = -1;
value = {};
index = [];

if ~isa(target, 'cell'),
  utlog('target must be a cell array',{'error', 'utpar_get_debug'});
  return;
end
len = length(target);
utlog(['length target = ',num2str(len)],{'utpar_get_debug'});

%default case, length 1
if len == 1,
  utlog('default case found',{'utpar_get_debug'});
  result = 0;
  value = target{:};
  index = [];
  utlog('exiting utpar_get',{'trace', 'utpar_get_debug'});
  return;
end

array = target{1};
location = target{2};
if ~isa(location,'char')
  utlog('location must be a string',{'error', 'utpar_get_debug'});
  return;
end
if ~isa(array,'cell')
  utlog(['can''t search in non-cell array for ''',location,''''],{'error', 'utpar_get_debug'});
  return;
end

utlog(['searching for ''',location,''''],{'utpar_get_debug'});
n = find(strcmp(location, array));

%found first part of location
if n >= 1,
  utlog(['found ''',location,''' at position ',num2str(n+1)],{'utpar_get_debug'});
  [value, index, result] = utpar_get({array{n+1},target{3:len}});
  if result == 0, %if everything good fill in index (otherwise stays empty)
    index = [n+1,index];
  end
else,  %if not found then look through defaults, if available

  utlog([location,' not found, searching in ''defaults'''],{'utpar_get_debug'});
  n = find(strcmp('defaults',array));
  if n >= 1,
    % if we find it amongst the defaults then return that value and index
    [value, index, result] = utpar_get({array{n+1},target{2:len}});
    if (result ~= -1) index = [index,n+1]; end
  else,
    utlog(['defaults not found'],{'utpar_get_debug'});
    value = {};
    index = []; 
  end %if n
end %if n >= 1

utlog('exiting utpar_get',{'trace', 'utpar_get_debug'});
