% Construct a new model, populate it with the library block specified, 
% set the block's parameters as required. Construct (and link to the block) 
% (input ports, Workspace In blocks) and (output ports, Workspace Out blocks)
% to allow data to be passed in and out.
%
% function[result] = utmodel_erect(varargin)
%
% result              = return code, (0 = success, -1 = error)  
% model               = constructed model, empty array if error
% varargin            = {'varname', value, ...} pairs. Valid varnames as follows; 
%   block_location    = library location of block
%   block_name        = name of block
%   block_version     = version of block to use (currently not used)
%   block_parameters  = cell array of parameter name, value pairs for block 
%   inputs            = cell array describing input ports with the following components;
%     name            = name of input port and source workspace variable
%     type            = data type
%     quantization    = quantization strategy for input data
%     bit_width       = bit width of data from input port
%     bin_pt          = binary point of data from input port
%   outputs           = cell array describing output ports with the following components;
%     name            = name of resultant output variable and output port
%     type            = type data should be interpretted as
%     bit_width       = bit width data should be interpretted as
%     bin_pt          = binary point data should be interpretted as

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

function[result] = utmodel_erect(varargin)

result = -1;
utlog('entering utmodel_erect',{'trace','utmodel_erect_debug'});

xoff = 150; xinc = 150; % initial x offset
yoff = 150; yinc = 100; % initial y offset
block_width = 100;      % width of central block 
port_width = 50;        % size of input/output port blocks 
port_depth = 12;        % depth per port 

defaults = { ...
  'model', { ...
    'name', 'pfb_fir_test', ...
    'blocks', { ...
      ' System Generator' { ...
        'name', ' System Generator', ...
        'source', 'library', ...
        'location', 'xbsIndex_r4/ System Generator', ...
        'parameters', {}, ...
        'position', [5 5 55 55], ... 
      }, ... %system generator
      'inputs', { ...
        'name', 'inputs', ...
        'source', 'scripted', ...
        'constructor', 'utinport_erect', ...
        'parameters', { ...
          'ports', { ...
            {'synci', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'quantization', 'Truncate', 'overflow', 'Flag as error', 'bit_width', 1, 'bin_pt', 0}}, ...
            {'din',   {'complex', 'on', 'parallelisation', 2,  'type', 'Signed', 'quantization', 'Round  (unbiased: +/- Inf)', 'overflow', 'Saturate', 'bit_width', 8, 'bin_pt', 7}}, ...
          }, ... %ports
        }, ... %parameters
        'position', [xoff yoff xoff+port_width yoff+5*port_depth], ...
      }, ... %inputs 
      'pfb_fir', { ...  
        'name', 'pfb_fir', ...
        'source', 'library', ...
        'location', 'casper_library_pfbs/pfb_fir', ...  
        'parameters', { ...
          'PFBSize', 6, ... 
          'TotalTaps', 2, ...
          'n_inputs', 1, ...
        }, ... %parameters
        'position', [xoff+port_width+xinc yoff xoff+port_width+xinc+block_width yoff+5*port_depth], ... 
      }, ... %pfb_fir
      'outputs', { ...
        'name', 'outputs', ...
        'source', 'scripted', ...
        'constructor', 'utoutport_erect', ...
        'parameters', { ...    
          'ports', { ...
            {'synco', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'bit_width', 1, 'bin_pt', 0}}, ...
            {'dout',  {'complex', 'on',  'parallelisation', 2, 'type', 'Signed',  'bit_width', 8, 'bin_pt', 7}}, ...
          }, ... %ports
        }, ... %parameters
        'position', [xoff+port_width+xinc+block_width+xinc yoff xoff+port_width+xinc+block_width+xinc+port_width yoff+5*port_depth]
      }, ... %outputs
    }, ... %blocks
    'lines', { ...
      {'inputs/1', 'pfb_fir/1'}, {'inputs/2', 'pfb_fir/2'}, {'inputs/3', 'pfb_fir/3'}, ...
      {'pfb_fir/1', 'outputs/1'}, {'pfb_fir/2', 'outputs/2'}, {'pfb_fir/3', 'outputs/3'}, ...
    }, ... %lines
    'triggers', { ...
      'pfb_fir', {'n_inputs'}, ...
    }, ... %triggers
  }, ... %model
};

args = {varargin{:}, 'defaults', defaults};
[model_name, temp, results(1)]  = utpar_get({args, 'model', 'name'});
[blocks, temp, results(2)]      = utpar_get({args, 'model', 'blocks'});
[lines, temp, results(3)]       = utpar_get({args, 'model', 'lines'});
if ~isempty(find(results ~= 0)),
  utlog(['error getting parameters'],{'error', 'utmodel_erect_debug'});
  return;
end

% create new model
sys = new_system(model_name);
% make it visible TODO make this optional for scripted tests
open_system(sys); 

if ~isa(blocks,'cell'),
  utlog(['blocks must be cell array'],{'error', 'utmodel_erect_debug'});
  return;
end

if mod(length(blocks),2) ~= 0,
  utlog(['blocks must be cell array of ''name'',''value'' pairs'],{'error', 'utmodel_erect_debug'});
  return;
end

%loop through constructing blocks
for block_index = 1:2:length(blocks), 
  block_name = blocks{block_index};
  block = blocks{block_index+1};
  if ~isa(block, 'cell'),
    utlog(['blocks must be cell arrays'],{'error', 'utmodel_erect_debug'});
    return;
  end
  if ~isa(block_name, 'char'),
    utlog(['block names must be strings'],{'error', 'utmodel_erect_debug'});
    return;
  end

  utlog(['erecting block ',model_name,'/',block_name],{'utmodel_erect_debug'});
 
  result = utblock_erect('model', model_name, 'block', block);
  if result ~= 0,
    utlog(['error erecting block ',num2str(ceil(block_index/2)),' in model ', model_name],{'error', 'utmodel_erect_debug'});
    return;
  end
end %for blocks

%loop through lines
for line_index = 1:length(lines),
  line = lines{line_index};
  if ~isa(line, 'cell') | length(line) ~= 2, 
    utlog(['lines must be cell arrays of length 2'],{'error', 'utmodel_erect_debug'});
    return;
  end

  if ~isa(line{1},'char') | ~isa(line{2},'char'),
    utlog(['line descriptions must be a pair of strings'],{'error', 'utmodel_erect_debug'});
    return;
  end 

  add_line(sys, line{1}, line{2});
end %for lines

result = 0;  %success
utlog('exiting utmodel_erect',{'trace','utmodel_erect_debug'});

