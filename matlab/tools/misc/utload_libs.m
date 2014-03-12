% Loads specified libraries
% 
% function return_code = utload_libs(varargin)
%
% return_code   = (0 = success)
% varargin      = {'varname', value, ... } pairs. Valid values for varname are;
%  libraries    = cell array of libraries to load  

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
  
function return_code = utload_libs(varargin)

log_group = 'utload_libs_debug';
utlog('entering', {log_group, 'trace'});

defaults = { 'libraries', {'casper_library_ffts', 'casper_library_misc'} }

libraries = utget_var('libraries', 'defaults', defaults, varargin{:});

return_code = -1;
%load the appropriate libraries
for lib_idx = 1:length(libraries),
  lib_name = libraries(lib_idx);
  if exist(lib_name, 'file') ~= 4,
      utlog(['Library ', lib_name, ' not accessible. Aborting...'],{'error', log_group});
  else
      warning('off', 'Simulink:SL_LoadMdlParameterizedLink')
      load_system(lib_name);
      utlog([lib_name, ' loaded'], {'trace', log_group});
      return_code = 0;
  end
end

utlog('exiting', {log_group, 'trace'});
