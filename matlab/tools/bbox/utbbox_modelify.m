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

%generates black box testing model that can be used with model functions
function[model, result] = utbbox_modelify(varargin)
result = -1; model = {};
log_group = 'utbbox_modelify_debug';

utlog('entering utbbox_modelify', {'trace', log_group});

%TODO pass this in from somewhere
xoff = 150; xinc = 150; % initial x offset
yoff = 150; yinc = 100; % initial y offset
block_width = 100;      % width of central block 
port_width = 30;        % size of input/output port blocks 
port_depth = 12; 

defaults = { ...
  'name', 'pfb_fir_test', ...
  'bbox', { ...
    'inputs', { ...       %description of input ports
      'ports', { ...
        {'synci', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'quantization', 'Truncate', 'overflow', 'Flag as error', 'bit_width', 1, 'bin_pt', 0}}, ...
        {'din', {'complex', 'on', 'parallelisation', 2, 'type', 'Signed', 'quantization', 'Round  (unbiased: +/- Inf)', 'overflow', 'Saturate', 'bit_width', 8, 'bin_pt', 7 }}, ...
        }, ... %ports
    }, ...   % inputs
    'outputs', { ...    %description of output ports
      'ports', { ...
        {'synco', {'complex', 'off', 'parallelisation', 1, 'type', 'Boolean', 'bit_width', 1, 'bin_pt', 0}}, ...
        {'dout', {'complex', 'on', 'parallelisation', 2, 'type', 'Signed', 'bit_width', 18, 'bin_pt', 17 }}, ...
      }, ... %ports
    }, ... %outputs     
    'block', { ...      %block to be connected to input and output ports
      'name', 'pfb_fir', ...
      'source', 'library', ...
      'location', 'casper_library_pfbs/pfb_fir', ...  
      'parameters', { ...
        'PFBSize', 4, ... 
        'TotalTaps', 3, ...
        'n_inputs', 1, ...
      }, ... %parameters
    }, ... %block
  }, ... %bbox     
  'base_model', { ... %model to add black box to
      'model', { ...
        'name', 'generic_model', ...
        'lines', {}, ...
        'settings', {}, ...
        'triggers', {}, ...
        'blocks', { ...
          ' System Generator' { ...
            'name', ' System Generator', ...
            'source', 'library', ...
            'location', 'xbsIndex_r4/ System Generator', ...
            'parameters', {}, ...
            'position', [5 5 55 55], ... 
          }, ... %system generator
        }, ... %blocks
      }, ... %model
  }, ... %base_model   
}; %defaults
args = {varargin{:}, 'defaults', defaults};
[bbox, tmp, rslt(1)]            = utpar_get({args, 'bbox'});
[inputs, tmp, rslt(2)]          = utpar_get({bbox, 'inputs'});
[in_ports, tmp, rslt(3)]        = utpar_get({bbox, 'inputs', 'ports'});
[outputs, tmp, rslt(4)]         = utpar_get({bbox, 'outputs'});
[out_ports, tmp, rslt(5)]       = utpar_get({bbox, 'outputs', 'ports'});
[block, tmp, rslt(6)]           = utpar_get({bbox, 'block'});
[block_name, tmp, rslt(7)]      = utpar_get({block, 'name'});
[base_model, tmp, rslt(8)]      = utpar_get({args, 'base_model'});
[model_name, tmp, rslt(9)]      = utpar_get({args, 'name'});

if ~isempty(find(rslt ~= 0)),
  utlog('error getting parameters',{'error',log_group});
  return;
end

%find the maximum port count (used in generating block sizes)

[n_inputs, result]  = utinport_nports(inputs{:});
if result ~= 0,
  utlog('error getting number inputs',{'error',log_group});
  return;
end
[n_outputs, result] = utoutport_nports(outputs{:});
if result ~= 0,
  utlog('error getting number outputs',{'error',log_group});
  return;
end
n_ports = max(n_inputs, n_outputs);

utlog(['number input ports = ',num2str(n_inputs),' number output ports = ',num2str(n_outputs)], {log_group});

%need new model
if isempty(base_model),

  if ~isa(model_name, 'char'),
    utlog('model name must be a string',{'error',log_group});
    return;
  end

  [model, result] = utmodel_modelify('name', model_name);
  if result ~= 0,
    utlog(['error constructing framework for model ',model_name],{'error',log_group});
    return;
  end

  utlog(['new model ',model_name,' framework constructed'], {log_group});
else,
  utlog(['modifying existing model'], {log_group});
  model = base_model;
  [model, result] = utpar_set({model, 'model'}, {'name', model_name});
  if result ~= 0,
    utlog('error setting name on base model', {'error', log_group});
  end
end

%add block to model
if ~isa(block, 'cell'),
  utlog('block must be a cell array',{'error',log_group});
  return;
end

position = [xoff+block_width+xinc, yoff, xoff+2*block_width+xinc, yoff+(n_ports*port_depth)];
[block, result] = utpar_insert({'position', position}, {block});
if result ~= 0,
  utlog(['error setting position for ',block_name],{'error',log_group});
  return;
end

[model, result] = utpar_insert({block_name, block}, {model, 'model', 'blocks'});
if result ~= 0,
  utlog(['error inserting ',block_name],{'error',log_group});
  return;
end

utlog([block_name,' added to model framework'], {log_group});

%generate inport from inputs
if ~isa(inputs,'cell'),
  utlog('inputs must be a cell array');
  return;
end

if ~isempty(inputs),
  inport = utinport_blockify('name', 'inputs', 'ports', in_ports, 'position', [xoff, yoff, xoff+block_width, yoff+(n_ports*port_depth)]);

  %add inport to model
  model = utpar_insert({'inputs', inport}, {model, 'model', 'blocks'});

  utlog(['inputs added to model framework'], {log_group});

  lines = utpar_get({model, 'lines'});
  %add appropriate lines or inputs
  for port_cnt = 1:n_inputs,
    line = {['inputs/',num2str(port_cnt)],[block_name,'/',num2str(port_cnt)]};
    lines = {lines{:},line}; 
  end

  %overwrite lines in model with 
%  model = utpar_set({model, 'model'}, {'lines', lines});

  utlog(['constructed lines for inputs'], {log_group});
end

%generate outport from outputs
if ~isa(outputs,'cell'),
  utlog('outputs must be a cell array');
  return;
end

if ~isempty(outputs),
  outport = utoutport_blockify('name', 'outputs', 'ports', out_ports, 'position', [xoff+2*block_width+2*xinc, yoff, xoff+3*block_width+2*xinc, yoff+n_ports*port_depth]);

  %add inport to model
  [model,result] = utpar_insert({'outputs', outport}, {model, 'model', 'blocks'});

  if result ~= 0,
    utlog('error adding outputs to blocks in model framework');
    return;
  end

  utlog(['outputs added to model framework'], {log_group});

%  lines = utpar_get('lines', model);
  %add appropriate lines for outputs
  for port_cnt = 1:n_outputs,
    line = {[block_name,'/',num2str(port_cnt)], ['outputs/',num2str(port_cnt)]};
    lines = {lines{:},line}; 
  end

  %overwrite lines in model with 
  model = utpar_set({model, 'model'}, {'lines',lines});

  utlog(['lines for outputs constructed, all lines added to model framework'], {log_group});
end

result = 0;
utlog('exiting utbbox_modelify', {'trace', log_group});
