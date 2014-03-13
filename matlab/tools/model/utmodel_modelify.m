%returns basic empty model populated with parameters if specified
%or defaults if not

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

function[model, result] = utmodel_modelify(varargin)
result=-1; model={};
log_group = 'utmodel_modelify_debug';
utlog('entering',{'trace', log_group});

defaults = { ...
  'name', 'default', ...
  'settings', {}, ...
  'blocks', {}, ...
  'lines', {}, ...
  'triggers', {}, ...
};
args = {varargin{:}, 'defaults', defaults};
name      = utpar_get({args,'name'});
settings  = utpar_get({args,'settings'});
blocks    = utpar_get({args,'blocks'});
lines     = utpar_get({args,'lines'});
triggers  = utpar_get({args,'triggers'});

%TODO sanity checking

model = { ...
  'model', { ...
    'name', name, ...
    'settings', settings, ...
    'blocks', blocks, ...
    'lines', lines, ...
    'triggers', triggers, ...  
  }, ... %model
};
 
utlog('exiting',{'trace', log_group});
result = 0;
