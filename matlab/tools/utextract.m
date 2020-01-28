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

function[data, en, result] = utextract(varargin)
data = []; result = -1;
log_group = 'utextract_debug';

utlog(['entering'],{'trace', log_group});

defaults = { ...
  'data', [0:15]', ...
  'mux', 4, ...
  'sync', [0;1;1;0], ...
  'en', 1, ...
  'fold_len', inf, ...
}; %defaults

args = {varargin{:}, 'defaults', defaults};
[data, temp, results(1)]      = utpar_get({args, 'data'});
[sync, temp, results(2)]      = utpar_get({args, 'sync'});
[en, temp, results(3)]        = utpar_get({args, 'en'});
[mux, temp, results(4)]       = utpar_get({args, 'mux'});
[fold_len, temp, results(5)]  = utpar_get({args, 'fold_len'});

if find(results(1) ~= 0),
  utlog(['error getting data'],{'error', log_group});
  return;
end
if find(results(4) ~= 0),
  utlog(['error in mux factor supplied'],{'error', log_group});
  return;
end

ldata = length(data);
lsync = length(sync);
len = length(en);

%TODO length checking

%sync processing
if lsync > 1,
  sync1 = find(sync==1);

  if isempty(sync1),
    utlog(['did not find syncs, using all data'],{'warning', log_group});
  end 
  
  if length(sync1) > 1,
    utlog(['multiple syncs found, using last'],{'warning', log_group});
  end 

  sync1 = sync1(length(sync1));
  
  utlog(['sync found at position ',num2str(sync1)],{log_group});
  utlog(['removing en after ',num2str(sync1)],{log_group});
  if len > 1,
    en = en(sync1+1:len,:);
  end; %if

  utlog(['removing data after ',num2str(sync1*mux)],{log_group});
  data = data(sync1*mux+1:ldata,:);
end %if lsync

ldata = length(data);
%en processing
if len > 1, %fluff if original length was greater than 1
  utlog(['fluffing en'],{log_group});
  len = length(en);

  en = repmat(en, 1, mux)';
  en = reshape(en, len*mux, 1);
  en = [en; zeros(ldata-(mux*len),1)];

  utlog(['masking data'],{log_group});
  data = data(find(en == 1));
end;

%fold data into columns if required
if fold_len ~= inf,
  folds = floor(length(data)/fold_len); 
  utlog([num2str(folds),' folds found'],{log_group});
  data = data(1:folds*fold_len);
  data = reshape(data, fold_len, folds);    
end

utlog(['exiting'],{'trace', log_group});
result = 0;
