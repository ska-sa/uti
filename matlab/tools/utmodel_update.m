% generic update of models
% function[result, model] = utmodel_update(varargin)
%
% Extracts specified parameters from blocks in the model and compares
% them to the updated values. If they differ, the list of parameters that
% trigger a redraw is consulted. If the model needs to be redrawn, a new
% model with the specified blocks and parameters is constructed using the
% specified initialisation function. If no reconstruction is necessary, 
% then the block specified is updated with the new parameters. The 
% resultant model is passed back.

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

function[model, result] = utmodel_update(varargin)

log_group = 'utmodel_update_debug';
utlog('entering utmodel_update', {'trace', log_group});
result = -1; model = [];

defaults = { ...
  'model', { ...
    'name', 'pfb_fir_test', ...
    'blocks', { ...
      'pfb_fir', { ...
        'parameters', {}, ...
      }, ... %pfb_fir
    }, ... %blocks
    'triggers', { ...           %blocks and parameters that trigger a redraw
      'pfb_fir', { ...
        'n_inputs' 
      } ... %pfb_fir
    } ... %triggers
  }, ... %model
  'updates', { ...            %blocks and parameters to update
    'pfb_fir', { ...
      'PFBSize', 4, ...
    } %pfb_fir          
  }, ... %updates 
}; %defaults

args = {varargin{:}, 'defaults', defaults};
updates     = utpar_get({args, 'updates'});
model       = utpar_get({args, 'model'});
triggers    = utpar_get({model, 'triggers'});
model_name  = utpar_get({model, 'name'});

%sanity checks
if ~isa(updates,'cell') | mod(length(updates),2) ~= 0,
  utlog(['the value for ''updates'' must be a cell array of ''block'', {updates} pairs'],{'error', log_group});
  return;
end

if ~isa(triggers,'cell'),
  utlog(['the value for ''triggers'' must be a cell array'],{'error', log_group});
  return;
end

sys = find_system('type', 'block_diagram', 'Name', model_name);
if isempty(sys),
  utlog(['model ',model_name,' not open'],{'error', log_group});
  return;
end

redraw = 0;

%go through each block in parameter list
for blk_index = 0:length(updates)/2-1,
  blk_name = updates{blk_index*2+1};
  blk_pars = updates{blk_index*2+2};
  if ~isa(blk_name,'char'),
    utlog(['block ',num2str(blk_index), ' error, names need to be strings'],{'error', log_group});
    return;
  end
  
  if ~isa(blk_pars,'cell'),
    utlog(['block ',num2str(blk_name), ' error, parameters need to be in cell array'],{'error', log_group});
    return;
  end

  %get parameters from block
  block = find_system(sys, 'Name', blk_name);
  if isempty(block),
    utlog(['block ',blk_name, ' not found in ',model_name],{'error', log_group});
    return;
  end
  utlog(['updating ',blk_name],{log_group});  

  %get all parameter Name,Value pairs
  vars = get_param(block, 'MaskWSVariables');
  vars = vars{1}; %returns cell array where first entry a struct
  if isempty(vars),
    utlog(['error retrieving vars from ',blk_name],{'error', log_group});  
    return;
  end

  existing = cell(1,length(vars)*2);
  for var_index = 0:length(vars)-1,
    var = vars(var_index+1);
    existing{var_index*2+1} = var.Name;
    existing{var_index*2+2} = var.Value;
  end

  %check existing parameters against requested updates
  [agg, par_cmp, result] = utpar_compare(blk_pars, {existing});
  if result < 0,
    utlog(['error comparing parameters from ',blk_name,' with requested updates'],{'error', log_group});  
    return;
  end
  utlog(['aggregate parameter comparison for block ',blk_name,' was ',num2str(agg)],{log_group});  

  %if the parameters don't match in some way 
  if agg ~= 1,

    %if the parameter/block combination occurs in triggers and the values don't match then break and redraw
    for trig_index = 1:2:length(triggers),
      trig_blk = triggers{trig_index};

      if ~isa(trig_blk,'char'),
        utlog(['name for trigger block ',num2str(trig_index),' not string'],{'error', log_group});  
        return;
      end    
      
      if strcmp(blk_name, trig_blk),
        utlog(['block ',blk_name,' and trigger block ',trig_blk,' match, checking variables'],{log_group});  

        %block variables that trigger a redraw
        trig_pars = triggers{trig_index+1};
        if ~isa(trig_pars,'cell'),
          utlog(['trigger parameters for trigger block ',trig_blk,' not cell array'],{'error', log_group});  
          return;
        end    
        
        %loop through all parameter updates, checking if in trigger list if has changed
        for trig_par_index = 1:length(trig_pars),
          trig_par = trig_pars{trig_par_index};
          [cmp_rslt, tmp, result] = utpar_get({par_cmp, trig_par});
          %if we find the trigger parameter in the list of updates, and the parameter value has changed or 
          % has a different type, or was not found in the parameters
          if result == 0 & cmp_rslt ~= 1,
            utlog(['change in ',trig_par,' in ',trig_blk, ' triggering redraw'],{log_group});  
            redraw = 1;
            break; %no need to keep going
          end
        end
      end %if strcmp(blk_name, trig_blk)    
 
      if redraw == 1, 
        break; 
      end
    end %for trig_index

    %if no redraw required, update block with parameters specified
    if redraw == 1, 
      break;
    else, %don't need redraw but do need block update  
      utlog(['updating ',blk_name],{log_group});

      %update the model description passed
      for par_index = 1:2:length(blk_pars),
        par_name = blk_pars{par_index};
        par_val = blk_pars{par_index+1};
        utlog(['setting ',par_name,' to ', utto_string(par_val)],{log_group});
        
        %find the blk and parameters in the model passed
        [model_tmp, result] = utpar_set({model, 'blocks', blk_name, 'parameters', par_name}, {par_val});
        %if not found, then add it 
        if result ~= 0,
          utlog(['parameter ',par_name, ' being added to parameters for ',model_name,'/',blk_name],{log_group});
          utpar_get({model, 'blocks', blk_name, 'parameters'})
          [model_tmp, result] = utpar_insert({par_name, par_val}, {model, 'blocks', blk_name, 'parameters'});
          if result ~= 0,
            utlog(['error adding parameter ',par_name, ' to parameters for ',model_name,'/',blk_name],{'error', log_group});
          else
            model = model_tmp;
          end
        else
          model = model_tmp;
        end %if result
        
      end

      %update the block in the model 
      [blk_pars_str, result] = utto_string(blk_pars);
      if result ~= -1,  
        set_param([model_name,'/',blk_name], blk_pars_str{:});
      else  
        utlog(['error converting ',model_name,'/',blk_name,'''s parameters to a string'],{log_group, 'error'});
      end
    end
  end %if agg == 0
end %for blk_index

if redraw ~= 0,
%TODO
  utlog(['redrawing ',model_name],{log_group});  
%if no init_fcn, return error
%otherwise close model, call the init function with existing parameters updated where appropriate
  utlog(['aaaarg, needs redraw but not implemented yet'],{'error', log_group});  
  result = -1;
end

result = 0;
utlog('exiting', {'trace', log_group});
