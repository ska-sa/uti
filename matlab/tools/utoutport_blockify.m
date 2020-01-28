%returns a block that can be inserted into a model or used with block stuff 

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


function[block,result] = utoutport_blockify(varargin)
block = {}; result = -1;
log_group = 'utoutport_blockify_debug';

utlog('entering utoutport_blockify',{'trace', log_group});

defaults = { ...
  'name', 'outputs', ...
  'ports', { ...
    {'sync', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'bit_width', 1, 'bin_pt', 0}}, ...
    {'name', {'dout', 'complex', 'on', 'parallelisation', 2, 'type', 'Signed', 'bit_width', 8, 'bin_pt', 7 }}, ...
  }, ... %ports
  'position', [50, 50, 250, 250], ...
};
args = {varargin{:}, 'defaults', defaults};
name      = utpar_get({args, 'name'});
ports     = utpar_get({args, 'ports'});
position  = utpar_get({args, 'position'});

block = { ...
  'name', name, ...
  'source', 'scripted', ...
  'constructor', 'utoutport_erect', ...
  'parameters', { ...
    'ports', ports, ...
  }, ...
  'position', position, ...
};
result = 0;

utlog('exiting utoutport_blockify',{'trace', log_group});
