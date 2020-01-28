% function = utoutport_erect(varargin)
%
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

function[result] = utoutport_erect(varargin)

result = -1;
log_group = 'utoutport_erect_debug';
utlog('entering utoutport_erect',{'trace', log_group});

defaults = { ...
  'target', gcb, ...
  'parameters', { ...
    'ports', { ...
      {'synco', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'bit_width', 1, 'bin_pt', 2}}, ...
      {'datao', {'complex', 'off',  'parallelisation', 2, 'type', 'Signed',  'bit_width', 8, 'bin_pt', 6}}, ...
      {'misco', ...
        { ...
          {'label',  {'complex', 'off', 'parallelisation', 4, 'type', 'Unsigned', 'bit_width', 4, 'bin_pt', 0}}, ...
          {'enable', {'complex', 'off', 'parallelisation', 4, 'type', 'Boolean',  'bit_width', 1, 'bin_pt', 0}}, ...
          {'misc',   {'complex', 'on',  'parallelisation', 2, 'type', 'Boolean',  'bit_width', 1, 'bin_pt', 0}}, ...
        }, ...
      }, ... %misc
    }, ... %ports
  }, ... %parameters    
};

xoff = 150; xinc = 150;                 % initial x offset
yoff = 150; yinc = 100;                 % initial y offset
port_width = 25; port_depth = 15;       % size of input port 

args = {varargin{:}, 'defaults', defaults};
blk     = utpar_get({args, 'target'});
ports   = utpar_get({args, 'parameters', 'ports'});

if ~isa(ports, 'cell'),
  utlog('ports must be a cell array', {'error', log_group});
  return;
end

utlog([num2str(length(ports)),' ports found'],{log_group});

%go through and process every port
yoff_rslt = yoff;
port_count = 0;
for port_index = 1:length(ports),
  port = ports{port_index};
  if ~isa(port, 'cell'),
    utlog('each port must be a cell array', {'error', log_group});
    return;
  end
  
  base_name = port{1};
  if ~isa(base_name, 'char'),
    utlog('the name of each port must be a string', {'error', log_group});
    return;
  end

  utlog(['processing port ',base_name],{log_group});

  %draw output port component
  [result, dest_blocks, yoff_rslt, bits] = utoutport_weave( ...
    'ports', {port}, ...
    'xoff', xoff+xinc, 'xinc', xinc, 'yoff', yoff, 'yinc', yinc, ...
    'composite', 'off', 'system', blk);
  len_dest_blocks = length(dest_blocks);

  ystep = (yoff_rslt-yoff)/len_dest_blocks; %determine space needed for all ports

  for comp_index = 1:len_dest_blocks,
    %add port 
    if len_dest_blocks > 1,
        port_name = [base_name, num2str(comp_index-1)];
    else
        port_name = base_name;
    end
    port_src = ['built-in/inport'];

    add_block(port_src, [blk, '/', port_name], 'Port', num2str(port_count+1), ...
      'Position', [xoff-port_width/2, yoff-port_depth/2, xoff+port_width/2, yoff+port_depth/2] );
    
    component = dest_blocks{comp_index};
    
    [r,c] = size(component);
    utlog(['got component with size ',num2str(r),' ',num2str(c)],{log_group});

    utlog(['adding link to '],{log_group});
    for block_index = 1:length(component),
      utlog([component{block_index}],{log_group});
      %link port/s  
      add_line(blk,[port_name,'/1'], [component{block_index},'/1']);
    end  
 
    yoff = yoff + ystep; 
    port_count = port_count+1;
  end %for comp_index

  yoff = yoff_rslt; %update to result from last port drawn;
end %for port_index

result = 0;  %success
utlog('exiting utoutport_erect',{'trace', log_group});

