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

function [dout, results] = utoutport_desimify(varargin)
dout = {}; result = -1;
log_group = 'utoutport_desimify_debug';
utlog('entering utoutport_desimify',{'trace', log_group});

time = [0:1:2^(5-2)-1]';
defaults = { ...
  'ports', { ... %output port description from model
    {'dout',  {'complex', 'on',  'parallelisation', 2}}, ...
    {'of',    {'complex', 'off', 'parallelisation', 1}}, ...
    {'synco', {'complex', 'off', 'parallelisation', 1}}, ...
  }, ... %ports
}; %defaults

args    = {varargin{:}, 'defaults', defaults};
[ports, temp, results(2)]       = utpar_get({args, 'ports'});

if ~isempty(find(results ~= 0)),
  utlog(['error getting parameters'],{'error', log_group});
  return;
end

%TODO error checking

%run through ports
for port_index = 1:length(ports),

    port = ports{port_index};
    port_name = port{1};

    if ~isa(port_name, 'char'),
      utlog(['port name must be a string'],{'error', log_group});
      return;
    end

    port_args = port{2};
    if ~isa(port_args, 'cell'),
      utlog(['port arguments must be a cell array'],{'error', log_group});
      return;
    end

    [parallelisation, temp, results(1)]   = utpar_get({port_args, 'parallelisation'});
    [complex, temp, results(2)]           = utpar_get({port_args, 'complex'});
    if ~isempty(find(results ~= 0)),
      utlog(['error getting parameters for port ',port_name],{'error', log_group});
      return;
    end

    %keeps track of length of data to ensure consistency
    prev_len = 0;
    data_temp = [];    

    found = 1;      
    %run through list of associated port names
    %note, structure is same as that generated with utoutport_weave
    for stream_index = 1:parallelisation,

      %generate names to find
      if parallelisation > 1,
        base_name = [port_name,num2str(stream_index-1)];
      else,
        base_name = port_name;
      end
      
      if strcmp(complex,'on'),
        final_names = {[base_name,'_real'], [base_name,'_imag']};
      else,  
        final_names = {base_name};
      end

      for component_index = 1:length(final_names),

        component = final_names{component_index};
        utlog(['locating ',component,'...'],{log_group});
       
        try,
          data_val = evalin('base', component);
        catch
          found = 0;
          utlog(['error getting value of ',component,' in base workspace'],{'error', log_group});
          return;
        end
        
        %insert data into temporary variable
        dest_col = (stream_index-1)*length(final_names)+component_index;
        utlog(['inserting ',component,' data into column ',num2str(dest_col)],{'utoutport_desimify_debug'});
        data_temp(:, dest_col) = data_val(:,1);

      end %for component_index
    end %for stream_index
 
    %mux
    [port_val, result] = utmux('data', data_temp, 'cplx', complex, 'vec_len', 0);
    if found ~= 1,
      utlog(['error muxing data for port ', port_name],{'error', log_group});
      return;
    end   
    utlog([port_name, ' muxed into vector ',num2str(length(port_val)),' long'],{log_group});

    %insert items into returned data
    dout = {dout{:}, port_name, port_val};

end %for port_index

utlog('exiting utoutport_desimify',{'trace', log_group});
result = 0;
