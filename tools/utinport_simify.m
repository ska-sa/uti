%takes an inport description and data and produces arguments suitable for passing to utmodel_sim

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

function[inputs, result] = utinport_simify(varargin)
ut_log_group = 'utinport_simify_debug';
inputs = {}; result = -1;
utlog('entering utinport_simify',{'trace', ut_log_group});

defaults = { ...
  'ports',  { ... %input port description from model
    {'synci', {'parallelisation', 1, 'complex', 'off'}}, ...
    {'shift', {'parallelisation', 1, 'complex', 'off'}}, ...
    {'din',   {'parallelisation', 2, 'complex', 'on'}}, ...
  }, ... %ports
  'inputs', { ... %data input
    {'synci', [1; zeros(2^(5-2)*4-1,1)]}, ...
    {'shift', [2^5.*ones(2^(5-2)*4,1)]}, ...
    {'din',   [0; 1; zeros(2^(5)*4-2,1)]}, ...
  }, ... %inputs
  'tick', 1, ...
}; %defaults

args    = {varargin{:}, 'defaults', defaults};
[ports, temp, results(1)]       = utpar_get({args, 'ports'});
[input_vars, temp, results(2)]  = utpar_get({args, 'inputs'});
[tick, temp, results(3)]        = utpar_get({args, 'tick'});
if ~isempty(find(results ~= 0)),
  utlog(['error getting parameters'],{'error', ut_log_group});
  return;
end

%run through data inputs
for input_index = 1:length(input_vars),
  input_datum = input_vars{input_index};
  if length(input_datum) ~= 2,
    utlog(['input ',num2str(input_index),' not name,value pair'],{'error', ut_log_group});
    return;
  end

  input_name = input_datum{1};
  if ~isa(input_name,'char'),
    utlog(['input ',num2str(input_index),' name not a string'],{'error', ut_log_group});
    return;
  end
  
  input_vals = input_datum{2};
  if ~isa(input_vals,'double'),
    utlog(['input ',input_name,' vals not doubles'],{'error', ut_log_group});
    return;
  end

  port_located = 'off';
  %locate matching port
  for port_index = 1:length(ports),
    port = ports{port_index};
    if length(port) ~= 2,
      utlog(['port ',num2str(input_index),' not name,value pair'],{'error', ut_log_group});
      return;
    end
  
    port_name = port{1}; 
    if ~isa(input_name,'char'),
      utlog(['port ',num2str(port_index),' name not a string'],{'error', ut_log_group});
      return;
    end
  
    %got a match
    if strcmp(port_name, input_name),
      utlog(['located input ', input_name,' in ports'],{ut_log_group})
      
      port_located = 'on';

      %get parameters
      port_pars = port{2};
      if ~isa(port_pars,'cell');
        utlog(['port ',num2str(port_index),' parameters not a cell array'],{'error', ut_log_group});
        return;
      end

      %find parallelisation factor
      [parallelisation, temp, result] = utpar_get({port_pars, 'parallelisation'});
      if result ~= 0,
        utlog(['port ',port_name, ' parameters do not contain ''parallelisation'''],{'error', ut_log_group});
        return;
      end  
      
      %find complex setting
      [complex, temp, result] = utpar_get({port_pars, 'complex'});
      if result ~= 0,
        utlog(['port ',port_name, ' parameters do not contain ''complex'''],{'error', ut_log_group});
        return;
      end  

      %demux data based on level of parallelisation
      [data, result] = utdemux('n_streams', parallelisation, 'complex', complex, 'din', input_vals);
      if result ~= 0,
        utlog(['error demuxing data for port ',port_name ],{'error', ut_log_group});
        return;
      end

      cols = parallelisation;
      if strcmp(complex,'on'),
        cols = cols*2;
      end
      %sanity check on returned data dimensions
      [r,c] = size(data);
      if c ~= cols,
        utlog(['error in returned demuxed data dimensions for ',port_name ],{'error', ut_log_group});
        return;
      end
        
      %the numbering and naming syntax below matches utinport_weave
      base_name = input_name;
      var_name = base_name;
      for stream_index = 1:parallelisation,
        if parallelisation > 1,
          var_name = [base_name, num2str(stream_index-1)];
        end
        if strcmp(complex, 'on'),
          final_name  = [var_name,'_real'];
          var_val   = data{stream_index*2-1};
          [r,c] = size(var_val); 
          var_time  = [0:tick:(r-1)*tick]';  
          inputs    = {inputs{:}, {final_name, [var_time, var_val]}};
          utlog(['adding ',final_name,' with size [',num2str(r),',',num2str(c),'] to inputs'],{ut_log_group})
          final_name  = [var_name,'_imag'];
          var_val   = data{stream_index*2};
          [r,c] = size(var_val); 
          var_time  = [0:tick:(r-1)*tick]';  
          inputs    = {inputs{:}, {final_name, [var_time, var_val]}};
          utlog(['adding ',final_name,' with size [',num2str(r),',',num2str(c),'] to inputs'],{ut_log_group})
        else,    
          var_val = data{stream_index};
          [r,c] = size(var_val);
          var_time  = [0:tick:(r-1)*tick]';  
          utlog(['adding ',var_name,' with size [',num2str(r),',',num2str(c),'] to inputs'],{ut_log_group})
          inputs = {inputs{:}, {var_name, [var_time, var_val]}};
        end
        utlog(['finished adding ',var_name,' to inputs'],{ut_log_group})
      end %for stream_index
      
      break; %break out of for loop      
    end %if strcmp 
  end %for port_index
  
  if ~strcmp(port_located, 'on'),
    utlog(['error locating port for input ',input_name ],{'error', ut_log_group});
    return;
  end

end %for input

utlog('exiting utinport_simify',{'trace', ut_log_group});
