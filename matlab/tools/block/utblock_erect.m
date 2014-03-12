% Construct a new block depending on type specified  
%
% function[result] = utblock_erect(varargin)
%
% result              = return code, (0 = success, -1 = error)  
% varargin            = {'varname', value, ...} pairs. Valid varnames as follows; 
%   model             = name of model to insert block into
%   name              = name of block
%   type              = type of block ('library', 'scripted')
%   location          = library location of block if a library block
%   constructor       = constructor function if a scripted block
%   parameters        = cell array of parameter name, value pairs for block 
%   position          = [xpos_top_left ypos_top_left xpos_bottom_right ypos_bottom_right] 

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

function[result] = utblock_erect(varargin)
result = -1;
log_group = 'utblock_erect_debug';
utlog('entering utblock_erect',{log_group, 'trace'});

defaults = { ...
  'model', gcs, ...
  'block', { ...
    'name', 'outputs', ...
    'source', 'scripted', ... %'location', 'casper_library_pfbs/pfb_fir', ...
    'constructor', 'utoutport_erect', ...
    'parameters', { ...
    }, ...
    'position', [100, 100, 250, 250] , ...
  }, ...
};

args = {varargin{:}, 'defaults', defaults};
[model, temp, results(1)]         = utpar_get({args, 'model'});
[block, temp, results(8)]         = utpar_get({args, 'block'});
[name, temp, results(2)]          = utpar_get({block, 'name'});
[source, temp, results(3)]        = utpar_get({args, 'block', 'source'});
if strcmp(source, 'library'), 
  [location, temp, results(4)]    = utpar_get({args, 'block', 'location'});
elseif strcmp(source, 'scripted'), 
  [constructor, temp, results(5)] = utpar_get({args, 'block', 'constructor'});
end
[parameters, temp, results(6)]    = utpar_get({args, 'block', 'parameters'});
[position, temp, results(7)]      = utpar_get({args, 'block', 'position'});
if ~isempty(find(results ~= 0)),
  utlog('error getting parameters', {'error', log_group});
  return;
end

%sanity checking

if ~isa(source,'char'),
  utlog(['source needs to be a string'],{'error', log_group});
  return;
end

if ~isa(model,'char'),
  utlog(['model needs to be a string'],{'error', log_group});
  return;
end

%if library block, check it exists, then add it as specified
if strcmp(source, 'library'),
  if ~isa(location,'char'),
    utlog(['location needs to be a string'],{'error', log_group});
    return;
  end

  % try to find library block specified
  % assumes libraries already loaded
  utlog(['trying to find library block ', location, '...'],{log_group});
  lib = [];
  try
    lib = find_system(location);
  catch
    utlog(['failure finding library block ',location],{'error', log_group});
  end
  if isempty(lib),
  else
    utlog(['success loading library block ',location],{log_group});
  end

  if ~isa(position,'double') || length(position) ~= 4,
    utlog('position must be a double array of length 4',{'error', log_group});  
    return;
  end

  dest = [model,'/',name];
  add_block(location, dest, 'Position', position);

  if ~isempty(parameters),
    %configure block with parameters converted to string
    [parameters_str, result] = utto_string(parameters);
    if result == 0,
      set_param(dest, parameters_str{:});
    else
      utlog(['Error converting block parameters to string'],{'error', log_group});
      return;
    end
  end  

%if scripted, 
elseif strcmp(source, 'scripted'),
 
  % add a generic subsystem with the name and position specified
  block_name = [model,'/',name];
  utlog(['adding ',block_name],{log_group}); 
  new_block = add_block('built-in/Subsystem', block_name, 'Position', position); 
  
  % call the constructor specified with parameters
  if ~isa(constructor,'char'),
    utlog(['constructor needs to be a string'],{'error', log_group});
    return;
  end
  
  if ~isa(parameters,'cell'),
    utlog(['parameters needs to be a cell array'],{'error', log_group});
    return;
  end

  %execute constructor 
  varargs = {'target', block_name, 'parameters', parameters};
  result = feval(constructor, varargs{:});

  if result ~= 0,
    utlog(['error calling ',constructor, ' for ',block_name],{'error', log_group});
    return;
  end

else,
  utlog(['don''t understand how to erect a ',source,' block'],{'error', log_group});
  return;
end %if source

result = 0;
utlog('exiting utblock_erect',{log_group, 'trace'});
