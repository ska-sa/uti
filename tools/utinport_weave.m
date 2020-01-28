% Constructs an input port from a (possibly multiple) Workspace In block/s, input ports. Also combines
% multiple inputs to form buses if required.
%
% function[result, src_block, xoff, yoff] = utinport_weave(varargin)
% 
% result            = return code (0 = success)
% src_block         = final block in chain (to be linked to input port on block)
% xoff              = x offset of final block
% yoff              = yinc past final y offset of final block
% varargin          = {'varname', value, ... } pairs. Valid values for varname are;
%  port_description = {'varname', value, ... } pairs describing each port, note that
%                     these can be nested when describing input data consisting of
%                     concatenated values (e.g complex). Valid values for varname are;
%   name            = name of input port and source workspace variable
%   type            = data type
%   bit_width       = bit width of data from input port
%   bin_pt          = binary point of data from input port
%   quantization    = input port quantization strategy when converting from floating to fixed point
%   overflow        = input port overflow strategy when converting from floating to fixed point
%  component        = component of an aggregate port 
%  xoff             = x offset to start drawing blocks at
%  xinc             = x increment when adding blocks
%  yoff             = y offset to start drawing blocks at
%  yinc             = y increment when adding blocks

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

function [result, src_blocks, xoff, yoff] = utinport_weave(varargin)
log_group = 'utinport_weave_debug';

utlog('entering utinport_weave',{'trace', log_group});

defaults = { ...
  'ports', ...
  { ...
    {'sync', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'bit_width', 1, 'bin_pt', 0, 'quantization', 'Truncate',                   'overflow', 'Flag as error'}}, ...
    {'data', {'complex', 'on',  'parallelisation', 4, 'type', 'Signed',  'bit_width', 8, 'bin_pt', 7, 'quantization', 'Round  (unbiased: +/- Inf)', 'overflow', 'Saturate'}}, ...
    {'misc', ... 
      { ...
        {'en',  {'complex', 'off', 'parallelisation', 2, 'type', 'Boolean', 'bit_width', 8, 'bin_pt', 0, 'quantization', 'Truncate',                   'overflow', 'Saturate'}}, ...
        {'tag', {'complex', 'on',  'parallelisation', 4, 'type', 'Signed',  'bit_width', 4, 'bin_pt', 3, 'quantization', 'Round  (unbiased: +/- Inf)', 'overflow', 'Wrap'}}, ...
      }, ...
    }, ...
  }, ...
  'component', 'off', ...
  'xoff', 200, 'xinc', 150, 'yoff', 100, 'yinc', 150, ...
  'system', gcs 
};

%constants
concat_width = 40;  concat_depth = 40; %concat 
ri_width = 60;      ri_depth = 20;     %reinterpret
portal_width = 60;  portal_depth = 20; %from workspace
port_width = 30;    port_depth = 20;   %input port

args = {varargin{:}, 'defaults', defaults};
system              = utpar_get({args, 'system'});
ports               = utpar_get({args, 'ports'});
xoff                = utpar_get({args, 'xoff'});
component           = utpar_get({args, 'component'});
xinc                = utpar_get({args, 'xinc'});
yoff                = utpar_get({args, 'yoff'});
yinc                = utpar_get({args, 'yinc'});

len_ports = length(ports);
utlog(['description of ',num2str(len_ports),' ports found'],{log_group});

if ~isa(ports,'cell'), 
  utlog('ports must be a cell array of {name, {description}} pairs',{'error', log_group});
  return
end

src_blocks = {};

for port_index = 1:len_ports,
  port = ports{port_index};

  name = port{1};
  port_description = port{2};

  %hit a port so add it and return reference for connection
  if ~isa(port_description{1}, 'cell'), %when hit bottom, find something besides cell arrays in first position   

    type            = utpar_get({port_description, 'type'});
    quantization    = utpar_get({port_description, 'quantization'});
    overflow        = utpar_get({port_description, 'overflow'});
    bit_width       = utpar_get({port_description, 'bit_width'});
    bin_pt          = utpar_get({port_description, 'bin_pt'});
    complex         = utpar_get({port_description, 'complex'});
    parallelisation = utpar_get({port_description, 'parallelisation'});

    utlog(['found port ',name], {log_group});

    %TODO parameter sanity checking

    for stream_index = 1:parallelisation,
      if parallelisation > 1, base_name = [name, num2str(stream_index-1)];
      else, base_name = name;
      end
    
      if strcmp(complex, 'on'), num_components = 2;
      else, num_components = 1;
      end
 
      for component_index = 0:num_components-1,  
        xoff_tmp = xoff; %reset x offset for every parallel stream and component of complex value
        if strcmp(complex, 'on'), 
          if component_index == 0, var_name = [base_name,'_real'];
          else var_name = [base_name, '_imag'];
          end
        else,
          var_name = base_name;
        end

        utlog(['adding ',var_name],{log_group});

        %add From Workspace 
        fw_src = ['built-in/From Workspace'];
        fw_name = [var_name, '_fw'];
        fw = add_block(fw_src, [system, '/', fw_name], ...
          'VariableName', var_name, ...
          'SampleTime', '1', ...
          'Position', [xoff_tmp-portal_width/2, yoff-portal_depth/2, xoff_tmp+portal_width/2, yoff+portal_depth/2] );
        xoff_tmp = xoff_tmp + xinc/2;

        %add input Port
        gi_src = ['xbsIndex_r4/Gateway In'];
        gi_name = [var_name,'_gi'];
        utlog(['Adding ',gi_name,' at x = ',num2str(xoff_tmp),', y = ',num2str(yoff)], log_group); 
        gi = add_block(gi_src, [system, '/', gi_name], ... 
          'arith_type', type, 'n_bits', num2str(bit_width), 'bin_pt', num2str(bin_pt), ...
          'quantization', quantization, 'overflow', overflow, ...    
          'Position', [xoff_tmp-port_width/2, yoff-port_depth/2, xoff_tmp+port_width/2, yoff+port_depth/2] );
        add_line(system, [fw_name,'/1'], [gi_name,'/1']); 

        %add reinterpret block if part of aggregate port or complex
        if (strcmp(component, 'on') || strcmp(complex,'on')) && strcmp(type, 'Signed'),
          xoff_tmp = xoff_tmp + xinc;
          ri_name = [var_name, '_ri'];
          ri = add_block('xbsIndex_r4/Reinterpret', [system,'/',ri_name], ...
            'force_arith_type', 'on', 'arith_type', 'Unsigned', ...
            'force_bin_pt', 'on', 'bin_pt', '0', ...
            'Position', [xoff_tmp-ri_width/2, yoff-ri_depth/2, xoff_tmp+ri_width/2, yoff+ri_depth/2]);
          add_line(system, [gi_name,'/1'], [ri_name,'/1']);
        end %if strcmp

        yoff = yoff + yinc; 
      end %for component_index

      %add concat block if complex
      if strcmp(complex, 'on'),
        yoff = yoff - yinc;     
   
        xoff_tmp = xoff_tmp + xinc;
        con_name = [base_name,'_con'];
        con = add_block('xbsIndex_r4/Concat', [system,'/',con_name], ...
          'num_inputs', '2', ...
          'Position', [xoff_tmp-concat_width/2, (yoff-yinc)-concat_depth/2, xoff_tmp+concat_width/2 ,(yoff-yinc)+concat_depth/2] );

        if strcmp(type, 'Signed'),
          %link up reinterpret blocks with concat in case of complex data
          add_line(system, [base_name, '_real_ri/1'], [con_name,'/1']);
          add_line(system, [base_name, '_imag_ri/1'], [con_name,'/2']);
        else, %complex but not Signed
          add_line(system, [base_name, '_real_gi/1'], [con_name,'/1']);
          add_line(system, [base_name, '_imag_gi/1'], [con_name,'/2']);
        end

        yoff = yoff + yinc;
      end %if complex
      
      %return the ports to be connected to
      if strcmp(complex,'on'),        %if complex
        src_blocks = {src_blocks{:}, con_name};
      elseif strcmp(component, 'on') && strcmp(type, 'Signed'), %if not complex but component port and needing reinterpret
        src_blocks = {src_blocks{:}, ri_name};
      else,                           %if not complex and not component    
        src_blocks = {src_blocks{:}, gi_name};
      end %if
    end %for stream_index 

  %not at port level yet so draw component port, joining components with concat blocks 
  else
    con_inputs = {}; 
    yoff_temp = yoff;
    xoff_max = 0; yoff_max = 0;
    %now loop through components in port_description 
    utlog(['Doing component port ',name],{log_group});
    [sub_rslt, src_blocks, xoff_result, yoff_temp] = utinport_weave(...
      'ports', port_description, ...
      'component', 'on', ...
      'xoff', xoff, 'xinc', xinc, 'yoff', yoff_temp, 'yinc', yinc, ...
      'system', system);
    utlog(['xoff: ',num2str(xoff),',yoff: ',num2str(yoff_temp)],log_group);
    
    %remember ports to join to concat
    con_inputs = {con_inputs{:},src_blocks{:}};
    xoff_max = max(xoff_result, xoff_max);
    yoff_max = max(yoff_temp-yinc, yoff_max); %yoff is where new block can be added so reduce by one

    num_components = length(con_inputs);

    utlog([num2str(num_components), ' drawn, joining with concat block'], log_group); 
    
    xoff = xoff_max + xinc;
    xoff_tmp = xoff;  
    %concat blocks for input as we unroll if needed, increasing x offset as we go
    if num_components > 1,
      con_name = [name,'_con'];
      [width,depth] = utdim(port_description);
      add_block('xbsIndex_r4/Concat', [system, '/', con_name], ...
        'num_inputs', num2str(num_components), ...
        'Position', [xoff-concat_width/2, yoff-concat_depth/2, ...
          xoff+concat_width/2 ,yoff_max+concat_depth/2] );
      %run through linking components to concat block
      for port = 1:num_components,
        add_line(system, [con_inputs{port},'/1'],[con_name,'/',num2str(port)]);
      end
      src_blocks = {con_name}; %pass final block back
    end
    yoff = yoff_max + yinc; %update yoff to next place we can add new blocks 
  end  %if ~isa(port_description, 'cell')

end %for port_index

xoff = xoff_tmp;

result = 0;

utlog('exiting utinport_weave',{'trace',log_group});
