% Constructs an output port from a (possibly multiple) Workspace Out block/s, output ports. Also splits
% output buses and converts and reinterprets the data as specified.
%
% function[result, dest_blocks, yoff, bool] = utoutport_weave(varargin)
% 
% result              = return code (0 = success)
% dest_blocks         = destination blocks to be linked to output port on block 
% yoff                = yinc past final port
% bits                = bits in bus output ports are sourced from
% bool                = whether the output port type was Boolean
% varargin            = {'varname', value, ... } pairs. Valid values for varname are;
%   port_description  = {'varname', value, ... } pairs describing each port, note that
%                       these can be nested when describing output data consisting of
%                       concatenated values (e.g complex). Valid values for varname are;
%     name             = name of output port and destination workspace variable
%     type             = data type
%     bit_width        = bit width of data going to output port 
%     bin_pt           = binary point of data going to output port
%   xoff               = x offset to start drawing blocks at
%   xinc               = x increment when adding blocks
%   yoff               = y offset to start drawing blocks at
%   yinc               = y increment when adding blocks

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

function [result, dest_blocks, yoff, bits] = utoutport_weave(varargin)

result = -1; dest_blocks = {}; yoff = 0; bits = 0;
log_group = 'utoutport_weave_debug';

utlog('entering utoutport_weave',{'trace', log_group});
%if a port is complex, it is assumed that it needs to be separated before output
%parallelisation factor generates many ports with labelling tying them together
%composite ports cause data to be sliced off
defaults = { ...
  'ports', ...
  { ...
    {'sync', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'bit_width', 1, 'bin_pt', 2}}, ...
    {'data', {'complex', 'off',  'parallelisation', 4, 'type', 'Signed',  'bit_width', 8, 'bin_pt', 6}}, ...
    {'misc', ...
      { ...
        {'label',  {'complex', 'off', 'parallelisation', 4, 'type', 'Unsigned', 'bit_width', 4, 'bin_pt', 0}}, ...
        {'enable', {'complex', 'off', 'parallelisation', 4, 'type', 'Boolean',  'bit_width', 1, 'bin_pt', 0}}, ...
        {'misc',   {'complex', 'on',  'parallelisation', 2, 'type', 'Boolean',  'bit_width', 1, 'bin_pt', 0}}, ...
      }, ...
    }, ... %misc
  }, ... %ports
  'xoff', 200, 'xinc', 150, 'yoff', 100, 'yinc', 150, ...
  'composite', 'off', ...
  'system', gcs 
};

%constants
slice_width = 30; slice_depth = 20; %slice
ri_width = 60;    ri_depth = 20;    %reinterpret
tw_width = 60;    tw_depth = 20;    %to workspace
go_width = 30;    go_depth = 20;    %gateway out

args = {varargin{:}, 'defaults', defaults};
system        = utpar_get({args, 'system'});
ports         = utpar_get({args, 'ports'});
xoff          = utpar_get({args, 'xoff'});
xinc          = utpar_get({args, 'xinc'});
yoff          = utpar_get({args, 'yoff'});
yinc          = utpar_get({args, 'yinc'});
composite     = utpar_get({args, 'composite'});

len_ports = length(ports);
utlog(['description of ',num2str(len_ports),' ports found'],{log_group});

if ~isa(ports,'cell'), 
  utlog('ports must be a cell array of {name, {description}} pairs', {'error', log_group});
  return
end

for port_index = 1:len_ports,

  port = ports{port_index};
  
  name = port{1};
  port_description = port{2};

  %hit a port so add it and return reference for connection
  if ~isa(port_description{1}, 'cell'), %when hit bottom, find something besides cell arrays in first position   

    type            = utpar_get({port_description, 'type'});
    bit_width       = utpar_get({port_description, 'bit_width'});
    bin_pt          = utpar_get({port_description, 'bin_pt'});
    parallelisation = utpar_get({port_description, 'parallelisation'});
    complex         = utpar_get({port_description, 'complex'});

    utlog(['making simple port ',name],{log_group});

    %TODO parameter sanity checking

    yoff_temp = yoff;
    dest_blocks = {};
    bits = 0;
    
    if strcmp(complex, 'on'),
      slice_bits = bit_width*2;
    else
      slice_bits = bit_width;
    end

    for stream_index = 1:parallelisation,
      xoff_temp = xoff; %reset x offset for every parallel stream 

      if parallelisation > 1, base_name = [name, num2str(stream_index-1)];
      else, base_name = name;
      end
    
      if strcmp(complex, 'on'), num_components = 2;
      else, num_components = 1;
      end

      %slice required if part of composite port
      if strcmp(composite, 'on'),
        comp_slice_block = 'Slice';
        comp_slice_src = ['xbsIndex_r4/', comp_slice_block];
        comp_slice_name = [base_name,'_comp_slice'];
        comp_slice = add_block(comp_slice_src, [system, '/', comp_slice_name], ...
          'boolean_output', 'off', ...
          'nbits', num2str(slice_bits), 'mode', 'Upper Bit Location + Width', ...
          'bit1', num2str(-1*bits), 'base1', 'MSB of Input', ...
          'Position', [xoff_temp-slice_width/2, yoff_temp-slice_depth/2, ...
          xoff_temp+slice_width/2 ,yoff_temp+slice_depth/2]);
        xoff_temp = xoff_temp + xinc;
      end %if composite

      xoff_pre = xoff_temp;
      dest_block = {};
      for component_index = 0:num_components-1, 
        xoff_temp = xoff_pre;
         
        if strcmp(complex, 'on'), 
          if component_index == 0, var_name = [base_name,'_real'];
          else var_name = [base_name, '_imag'];
          end
        else,
          var_name = base_name;
        end
  
        if strcmp(type, 'Boolean'), bool = 'on';
        else bool = 'off';
        end

        %add a slice block if part of complex type or 
        if strcmp(complex, 'on') || strcmp(type, 'Boolean'),
          slice_block = 'Slice';
          slice_src = ['xbsIndex_r4/', slice_block];
          slice_name = [var_name,'_slice'];
          slice = add_block(slice_src, [system, '/', slice_name], ...
            'boolean_output', bool, ...
            'nbits', num2str(bit_width), 'mode', 'Upper Bit Location + Width', ...
            'bit1', num2str(-1*component_index*bit_width), 'base1', 'MSB of Input', ...
            'Position', [xoff_temp-slice_width/2, yoff_temp-slice_depth/2, ...
            xoff_temp+slice_width/2 ,yoff_temp+slice_depth/2]);
          if strcmp(composite, 'on'),
            add_line(system, [comp_slice_name,'/1'], [slice_name,'/1']);
          end
          xoff_temp = xoff_temp + xinc;
        end %if complex

        %reinterpret block if not Boolean (Boolean done by slice block above)
        if ~strcmp(type, 'Boolean'),
          ri_block = 'Reinterpret';
          ri_src = ['xbsIndex_r4/', ri_block];
          ri_name = [var_name,'_ri'];
          add_block(ri_src, [system,'/',ri_name], ... 
            'force_arith_type', 'on', 'arith_type', type, ...
            'force_bin_pt', 'on', 'bin_pt', num2str(bin_pt), ...
            'Position', [xoff_temp-ri_width/2, yoff_temp-ri_depth/2, ...
            xoff_temp+ri_width/2 ,yoff_temp+ri_depth/2]);
          if strcmp(complex, 'on'),
            add_line(system, [slice_name,'/1'], [ri_name,'/1']);
          elseif strcmp(composite, 'on'),
            add_line(system, [comp_slice_name,'/1'], [ri_name,'/1']);
          end
          xoff_temp = xoff_temp + xinc;
        end

        %add output Port
        go_block = 'Gateway Out'; 
        go_src = ['xbsIndex_r4/', go_block];
        go_name = [var_name, '_go'];
        utlog(['Adding ',go_name,' at x = ',num2str(xoff_temp),', y = ',num2str(yoff_temp)], log_group); 
        add_block(go_src, [system, '/', go_name], ...
          'Position', [xoff_temp-go_width/2, yoff_temp-go_depth/2, xoff_temp+go_width/2, yoff_temp+go_depth/2] );
        xoff_temp = xoff_temp + xinc;
        
        if ~strcmp(type, 'Boolean'), 
          add_line(system, [ri_name,'/1'], [go_name,'/1']);
        else
          add_line(system, [slice_name,'/1'], [go_name,'/1']);
        end

        %add To Workspace block 
        tw_block = 'To Workspace';
        tw_src = ['built-in/', tw_block];
        tw_name = [var_name,'_tw'];
        utlog(['Adding ',tw_name,' at x = ',num2str(xoff_temp),', y = ',num2str(yoff_temp)], 'utoutport_weave_debug'); 
        add_block(tw_src, [system,'/',tw_name], ...
          'VariableName', var_name, ...
          'MaxDataPoints', 'inf', ...
          'Position', [xoff_temp-tw_width/2, yoff_temp-tw_depth/2, ...
          xoff_temp+tw_width/2, yoff_temp+tw_depth/2] );
        xoff_temp = xoff_temp + xinc;
        add_line(system, [go_name,'/1'],[tw_name,'/1']); 

        %set up blocks to pass back
        if strcmp(composite, 'on'),
          dest_block = {comp_slice_name};
        elseif strcmp(complex, 'on') || strcmp(type, 'Boolean'),
          dest_block = {dest_block{:}, slice_name};
        elseif ~strcmp(type, 'Boolean'),
          dest_block = {ri_name};
        else 
          dest_block = {go_name};
        end

        yoff_temp = yoff_temp + yinc;
        bits = bits + bit_width; %pass back bit width to feed back to slices
      end %for component_index
  
      dest_blocks = {dest_blocks{:}, dest_block};
   
    end %for stream_index

    yoff = yoff_temp;
    result = 0;

  %not at port yet so make slice block and then continue constructing port
  else
    num_components = length(port_description);
    
    utlog(['making component port ',name,' with ',num2str(num_components),' components'],{log_group});
    con_inputs = cell(1,num_components);  

    dest_blocks = {}; yoff_temp = yoff; xoff_temp = xoff; bits = 0; yoff_max = 0;
    dest_block = {};
    %now loop through components in port_description 
    for component = 1:num_components,   
      utlog(['component ',num2str(component)],{log_group});

      %slice block for each partition
      slice_src = 'xbsIndex_r4/Slice';
      slice_name = [name,num2str(component)];
      slice = add_block(slice_src, [system, '/', slice_name], ...
        'Position', [xoff-slice_width/2, yoff_temp-slice_depth/2, ...
        xoff+slice_width/2 ,yoff_temp+slice_depth/2]);
      xoff_temp = xoff + xinc;

      %do partition
      [code_rslt, dest_rslt, yoff_temp, bits_rslt] = utoutport_weave(...
        'ports', {port_description{component}}, ...
        'xoff', xoff_temp, 'xinc', xinc, 'yoff', yoff_temp, 'yinc', yinc, ...
        'composite', 'on', 'system', system);

      %remember the furthest down we have gone
      yoff_max = max(yoff_max, yoff_temp);
   
      %slice appropriate bits
      set_param(slice, ...
        'boolean_output', 'off', ...
        'nbits', num2str(bits_rslt), 'mode', 'Upper Bit Location + Width', ...
        'bit1', num2str(-1*bits), 'base1', 'MSB of Input');
     
      %join members of component to slice block
      for member = 1:length(dest_rslt),
        dest = dest_rslt{member};
        for index = 1:length(dest),
          add_line(system, [slice_name,'/1'], [dest{index},'/1']);
        end
      end       

      dest_block = {dest_block{:}, slice_name};
      bits = bits + bits_rslt;    

    end %for component

    dest_blocks = {dest_block};
    yoff = yoff_max; 
    bool = 'off';
    result = 0;
  end %if
end %for

utlog('exiting utoutport_weave',{'trace', log_group});
  
