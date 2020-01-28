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

function[n_ports, result] = utoutport_nports(varargin)

log_group = 'utoutport_nports_debug';
utlog('entering utoutport_nports',{'trace', log_group});
n_ports = 0;
result = -1;
ports = utpar_get({varargin,'ports'});

if ~isa(ports, 'cell'),
  utlog('ports must be a cell array',{'error', log_group});
  return;
end

if ~isempty(ports),

  utlog([num2str(length(ports)),' ports found, possibly parallelised and complex'],{log_group});
  %run through all ports 
  for port_index = 1:length(ports),
    
    port = ports{port_index};
    
    if ~isa(port, 'cell'),
      utlog('each port in ''ports'' must be a cell array',{'error', log_group});
      return;
    end

    %name in the first place indicates a leaf port
    if isa(port{1},'char'),
      in_name   = port{1};
      in_par    = utpar_get({port{2}, 'parallelisation'});

      utlog(['parallelisation = ', num2str(in_par)],{log_group});
      utlog(['name = ', in_name],{log_group});

      n_ports = n_ports + in_par;
      utlog(['final total of ports for ',in_name,' = ', num2str(in_par)],{log_group});
    else
      utlog(['each port in ''ports'' must start with a name'],{'error', log_group});
      return
    end %if isa(port{1}, 'char')
    
  end %for port_index  
  utlog(['final total for all ports = ', num2str(n_ports)],{log_group});
else
  utlog(['empty port array, bailing'],{log_group});
end %if ~isempty(ports)
result = 0;

utlog('exiting utoutport_nports',{'trace', log_group});
