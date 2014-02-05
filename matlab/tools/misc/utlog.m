% Output logging information depending on current logging strategy. 
%
% function utlog(msg, groups)
% 
% msg = text msg to display
% groups = logging group/s
%
% All log messages contained in the groups specified by 'ut_log_groups' in your
% Workspace will be displayed if they are not in 'ut_nolog_groups'. If casper_log_groups 
% is not defined, no log messages will be displayed.
% 
% Pre-defined groups; 
% 'all': allows all log entries to be displayed 
% '<file_name>_debug': low-level debugging log entries for specific file
% 'trace': used to trace flow through files
% 'error': errors
%  
% e.g ut_log_groups='trace', ut_nolog_groups={} - only 'trace' messages will be displayed
% e.g ut_log_groups={'all'}, ut_nolog_groups='trace' - log messages from any group except 'trace' will be dispalyed
% e.g ut_log_groups={'trace', 'error', 'adder_tree_init_debug'}, ut_nolog_groups = {'snap_init_debug'} - 'trace', 'error' 
% and messages from the 'adder_tree_init_debug' groups will be displayed (where debug messages in 'adder_tree_init.m' are defined 
% as belonging to the 'adder_tree_init_debug' group. 'snap_init_debug' messages will not be displayed however.

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

function utlog(msg, groups)
%default names of workspace log-level related variables
sys_log_groups_var = 'ut_log_groups';
sys_nolog_groups_var = 'ut_nolog_groups';
%sys_log_file_var = 'ut_log_file'; %TODO output to file 

if ~isa(groups,'cell'), groups = {groups}; end 

% if a log level variable of the specified name does not exist in the base 
% workspace exit immediately
if evalin('base', ['exist(''',sys_log_groups_var,''')']) == 0 return; end
sys_log_groups = evalin('base',sys_log_groups_var);
if ~isa(sys_log_groups,'cell'), sys_log_groups = {sys_log_groups}; end 

sys_nolog_groups = {};
if evalin('base', ['exist(''',sys_nolog_groups_var,''')']) ~= 0,
  sys_nolog_groups = evalin('base',sys_nolog_groups_var);
end
if ~isa(sys_nolog_groups,'cell'), sys_nolog_groups = {sys_nolog_groups}; end 

loc_all = strmatch('all', sys_log_groups, 'exact');
ex_loc = [];
loc = [];
% convert single element into cell array for comparison

for n = 1:length(groups),
  %search for log group in log groups to exclude
  ex_loc = strmatch(groups{n}, sys_nolog_groups, 'exact');
  %bail out first time we find it in the list to exclude
  if ~isempty(ex_loc) break; end
 
  %search for log group in log groups to display
  if isempty(loc), loc = strmatch(groups{n}, sys_log_groups, 'exact'); end

end

%display if found in one of groups to include and not excluded
if ~(isempty(loc) && isempty(loc_all)) && isempty(ex_loc) , 
  group_string = [];
  for n = 1:length(groups), 
    if n ~= 1, group_string = [group_string, ', ']; end
    group_string = [group_string, groups{n}];  
  end
  disp([group_string,': ',msg]);
end
