% generic simulation of model returning results in data

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

function[data, result] = utmodel_sim(varargin)
log_group = 'utmodel_sim_debug';

utlog('entering', {'trace', log_group});
result = -1; data = {};
[din, result] = utdata_gen('sources', {'noise', {'power', (2^0)/(2^12)}} , 'vec_len', 4*2^12);

defaults = { ...
  'model', { ... 
    'name', 'pfb_fir_real_test', ...
    'blocks', { ...
      'pfb_fir_real', { ...
        'parameters', { ...
          'PFBSize', 5, ...
          'n_inputs', 2, ...
        }, ... %parameters
      }, ... %pfb_fir_real
      'inputs', { ...
        'parameters', { ...
          'ports',  { ... %input port description from model
            {'synci', {'parallelisation', 1, 'complex', 'off'}}, ...
            {'din',   {'parallelisation', 4, 'complex', 'off'}}, ...
          }, ... %ports
        }, ... %parameters
      }, ... %inputs
      'outputs', { ...
        'parameters', { ...
          'ports', { ... %output port description from model
            {'dout',  {'complex', 'off',  'parallelisation', 4}}, ...
            {'synco', {'complex', 'off', 'parallelisation', 1}}, ...
          }, ... %ports
        }, ... %parameters
      }, ... %outputs
    }, ... %blocks
  }, ... %model
  'inputs', { ...
      {'synci',    [1;zeros((2^12)-1,1)]}, ...  %[1;0;zeros(2^(5-2)*4,1)]}, ...
      {'din',      din}, ... %[0;0;0;0;0;1.125;0;0;0*ones(2^10*4-8,1)]}, ...
  }, ... %inputs
  'sim_time', 2^6*8, ...
}; %defaults

args = {varargin{:}, 'defaults', defaults};
[model, temp, results(1)]        = utpar_get({args, 'model'});
[blocks, temp, results(2)]       = utpar_get({model, 'blocks'});
[input_ports, temp, results(3)]  = utpar_get({blocks, 'inputs', 'parameters', 'ports'});
[output_ports, temp, results(4)] = utpar_get({blocks, 'outputs', 'parameters', 'ports'});
[inputs, temp, results(5)]       = utpar_get({args, 'inputs'});
[name, temp, results(6)]         = utpar_get({model, 'name'});
[sim_time, temp, results(7)]     = utpar_get({args, 'sim_time'});
if ~isempty(find(results ~= 0)),
  utlog(['error getting parameters'],{'error', log_group});
  return;
end

%convert port description and data into final variables
[vars, result] = utinport_simify('ports', input_ports, 'inputs', inputs);
if result ~= 0,
  utlog(['error simifying inputs'],{'error', log_group});
  return;
end %if

var_len = length(vars);

utlog(['setting up ',name,'''s workspace with ',num2str(var_len),' input variables'], {log_group});

%set up variables in model's workspace
try,
  hws = get_param(name,'modelworkspace');
catch
  utlog(['error getting workspace from ',name],{'error', log_group});
  return;
end

% assign variables in model's workspace with values
for var_index = 1:var_len,
  var = vars{var_index};
  %TODO error checking
  var_name = var{1};
  var_val = var{2};
 
  if ~isa(var_name,'char'),
    utlog(['variable name must be a string in ''name'',''value'' pairs in ''inputs'''],{'error', log_group});
    return;
  end
  %TODO type checking of value

  [r,c] = size(var_val);
  
  utlog(['assigning ''',var_name,''' in ',name], {log_group});

  try,
    assignin(hws, var_name, var_val);
  catch
    utlog(['error assigning value to ',var_name,' in ',name,'''s workspace'],{'error', log_group});
    return;
  end
end

sim_time = floor(sim_time);
utlog(['simulating for ',num2str(sim_time),' samples ...'], {log_group});

oldopts = simget(name);
sim_options = { ...
  'DstWorkspace', 'base', ...
%  'Solver', 'FixedStepDiscrete', ... 
};

%TODO make solver type explicit instead of disabling warning
%(currently causes error for some reason)
warning off Simulink:Engine:UsingDiscreteSolver
newopts = simset(oldopts, 'DstWorkspace', 'base'); % 'Solver', 'FixedStepDiscrete'); 
%SIMULATE!
sim(name, sim_time, newopts);

%extract data from variables in model's workspace
utlog(['getting data from ',name,'''s workspace'], {log_group});

[data, result] = utoutport_desimify('ports', output_ports);
if result ~= 0,
  utlog(['error desimifying'],{log_group});
  return;
end %if

utlog('exiting', {'trace', log_group});
