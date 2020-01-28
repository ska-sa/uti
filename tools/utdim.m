% Return dimensions of input cell array
% function [width, depth] = utdim(input)
%
% width = total number of elements in input
% depth = largest amount of nesting in input 
% input = cell array (possibly nested) 

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

function [width, depth] = utdim(input)

log_group = 'utdim_debug';
utlog('entering', {log_group, 'trace'});
width = 0; depth = 0;
if isempty(input),
  return;
end

if ~isa(input,'cell'),
  width = 1; 
  return;
end

%go through current array, 
%finding dimensions of component values
for n = 1:length(input)
  [sub_width, sub_depth] = utdim(input{n});
  width = width+sub_width;
  depth = max(depth,sub_depth);
end

depth = depth + 1;

utlog('exiting', {log_group, 'trace'});
