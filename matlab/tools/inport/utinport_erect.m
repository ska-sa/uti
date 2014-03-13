% function = utinport_erect(varargin)
%

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

function[result] = utinport_erect(varargin)
log_group = 'utinport_erect_debug';

result = -1;
utlog('entering utinport_erect',{'trace',log_group});

defaults = { ...
  'target', gcb, ...
  'parameters', { ...
    'ports', { ...
      {'synci', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'quantization', 'Truncate',                   'overflow', 'Flag as error', 'bit_width', 1,  'bin_pt', 0}}, ...
      {'din',   {'complex', 'on',  'parallelisation', 4, 'type', 'Signed',  'quantization', 'Round  (unbiased: +/- Inf)', 'overflow', 'Saturate',      'bit_width', 18, 'bin_pt', 17}}, ...
      {'misc', ...
        { ...
          {'en',  {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'quantization', 'Truncate',                   'overflow', 'Flag as error', 'bit_width', 1, 'bin_pt', 0}}, ...
          {'tag', {'complex', 'off', 'parallelisation', 4, 'type', 'Signed',  'quantization', 'Round  (unbiased: +/- Inf)', 'overflow', 'Saturate',      'bit_width', 8, 'bin_pt', 7 }}, ...
        }, ...
      }, ... %misc
    }, ... %ports
  }, ... %parameters
}; %defaults

xoff = 150; xinc = 150;                 % initial x offset
yoff = 150; yinc = 100;                 % initial y offset
port_width = 25; port_depth = 15;       % size of output port 
args = {varargin{:}, 'defaults', defaults};
ports     = utpar_get({args, 'parameters', 'ports'});
blk       = utpar_get({args, 'target'});
  
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

  %draw input port component
  [result, dest_ports, xoff_rslt, yoff_rslt] = utinport_weave( ...
    'ports', {port}, ...
    'xoff', xoff, 'xinc', xinc, 'yoff', yoff, 'yinc', yinc, ...
    'component', 'off', 'system', blk);
  len_dest_ports = length(dest_ports);

  ystep = (yoff_rslt-yoff)/len_dest_ports; %determine space needed for all ports

  for comp_index = 1:len_dest_ports,
    
    dest_port = dest_ports{comp_index};

    %add port 
    port_src = ['built-in/outport'];
    if length(dest_ports) > 1, 
      port_name = [base_name, num2str(comp_index-1)];
    else port_name = base_name;
    end
    add_block(port_src, [blk, '/', port_name], 'Port', num2str(port_count+1), ...
      'Position', [(xoff_rslt+xinc)-port_width/2, yoff-port_depth/2, (xoff_rslt+xinc)+port_width/2, yoff+port_depth/2] );
    
    %link port/s  
    add_line(blk, [dest_port,'/1'], [port_name,'/1']);
   
    yoff = yoff + ystep; 
    port_count = port_count+1;
  end %for comp_index

  yoff = yoff_rslt; %update to result from last port drawn;
end %for port_index

result = 0;  %success
utlog('exiting utinport_erect',{'trace',log_group});

