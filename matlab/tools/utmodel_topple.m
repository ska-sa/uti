% Destroy a model created with uterect_mdl
%
% function[result] = utmodel_topple(varargin)
%
% result              = return code, (0 = success, -1 = error)  
% varargin            = {'varname', value, ...} pairs. Valid varnames as follows; 
%   model             = model created with uterect_mdl

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

function[result] = utmodel_topple(varargin)
log_group = 'utmodel_topple_debug';

result = -1; 
utlog('entering',{'trace', log_group});

defaults = { ...
  'model', 'untitled'
};

args = {varargin{:}, 'defaults', defaults};
name = utpar_get({args, 'model', 'name'});

close_system(name);

result = 0;
utlog('exiting',{'trace', log_group});
