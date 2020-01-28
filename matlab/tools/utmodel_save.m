% Save a model created with uterect_mdl
%
% function[result] = utmodel_save(varargin)
%
% result              = return code, (0 = success, -1 = error)  
% varargin            = {'varname', value, ...} pairs. Valid varnames as follows; 
%   model             = model created with uterect_mdl
%   location          = location to save model to

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

function [result] = utmodel_save(varargin)

log_group = 'utmodel_save_debug';
result = -1; 
utlog('entering',{'trace', log_group});

defaults = { ...
  'model', 'untitled', ...
  'location', '' 
};

args = {varargin{:}, 'defaults', defaults};
model_name = utget_var({args, 'model', 'name'});
location   = utget_var({args, 'location'});

file_name = [location,model_name];
try
  name = save_system(model, file_name);
catch
  utlog(['error saving ',model_name,' to ''',file_name,''], {'error', log_group});
  error(['utmodel_save: error saving ',model_name,' to ''',file_name,'']);
end

result = 0;
utlog(['saved ',model_name,' to ''',file_name,''], log_group);
utlog('exiting',{'trace', log_group});

