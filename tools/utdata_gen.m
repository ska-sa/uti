%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%   SKA Africa                                                                %
%   http://www.kat.ac.za                                                      %
%   Copyright (C) 2013 Andrew Martens (andrew@ska.ac.za)                      %
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

%allows the generation of various types of data suitable for test purposes
function[data, result] = utdata_gen(varargin)
  result = -1;
  ut_log_group = 'utdata_gen_debug';
  utlog('entering utdata_gen',{'trace', ut_log_group});

  defaults = {
    'sources', {'sinusoid', {'amplitude', 0.125}}, ... % 'dc', 'sinusoid', 'impulse' 
    'vec_len', 2^12, ...
  };
  args = {varargin{:}, 'defaults', defaults};
  [sources, temp, results(1)]   = utpar_get({args, 'sources'});   % list of data sources 
  [vec_len, temp, results(2)]    = utpar_get({args, 'vec_len'});    % length of final vector

  if ~isempty(find(results ~= 0)),
    utlog('error getting parameters from varargin',{'error', ut_log_group});
  end

  % parameter checking
  if mod(length(sources), 2) ~= 0,
    utlog('sources must be a list of ''name'', {value} pairs', {'error', ut_log_group});
    error('sources must be a list of ''name'', {value} pairs');
  end

  %TODO different functions?
  noise_defaults = { ...
    'power', 2^3/2^8, ...
    'mean', 0, ...
    'random', 'off', ...  %random generator set to particular seed if not random
    'seed', 0, ...        %TODO
  };

  dc_defaults = { ...
    'power', 2^3/2^8, ...
  }; 

  sinusoid_defaults = { ...
    'cycles', 10, ...          %wavelengths per period
    'period', 2^12, ...
    'amplitude', 1/2^3, ...
    'phase_offset', 0, ...
  };  
  
  impulse_defaults = { ...
    'amplitude', 0.5, ...
    'type', 'single', ... %'single', 'periodic'
    'offset', 0, ...
    'period', 2^8, ...    %if periodic
  };

  data = zeros(vec_len,1);
  
  for src_index = 1:length(sources)/2,
    src_type        = sources{src_index * 2-1};
    src_args        = sources{src_index * 2};

    if strcmp(src_type, 'noise'),
      noise_args = {src_args{:}, 'defaults', noise_defaults};
      [noise_power, temp, results(1)]   = utpar_get({noise_args, 'power'});
      [noise_mean, temp, results(2)]    = utpar_get({noise_args, 'mean'});
      [noise_random, temp, results(3)]  = utpar_get({noise_args, 'random'});
      [noise_seed, temp, results(4)]    = utpar_get({noise_args, 'seed'});
      if ~isempty(find(results ~= 0)),
        utlog('error getting arguments for noise source', {'error', ut_log_group});
        error('error getting arguments for noise source');
      end
                
      utlog(['adding guassian distibuted white noise with ',num2str(noise_power), ' std and ',num2str(noise_mean),' mean'], {ut_log_group});
      if strcmp(noise_random, 'off'), 
        reset(RandStream.getGlobalStream, noise_seed);
      end
      noise                 = noise_mean + (noise_power*randn(vec_len,1)); %normally distributed white noise
      data                  = data + noise; 

    elseif strcmp(src_type, 'dc'),
      dc_args = {src_args{:}, 'defaults', dc_defaults};
      [dc_power, temp, results(1)]   = utpar_get({dc_args, 'power'});
      if ~isempty(find(results ~= 0)),
        utlog('error getting arguments for dc source', {'error', ut_log_group});
        error('error getting arguments for dc source');
      end
                
      utlog(['adding dc component'], {ut_log_group});
      dc                    = dc_power*ones(vec_len,1);
      data                  = data + dc;      

    elseif strcmp(src_type, 'sinusoid'),
      sin_args = {src_args{:}, 'defaults', sinusoid_defaults};
      [sin_cycles, temp, results(1)]       = utpar_get({sin_args, 'cycles'});
      [sin_amplitude, temp, results(2)]    = utpar_get({sin_args, 'amplitude'});
      [sin_period, temp, results(3)]       = utpar_get({sin_args, 'period'});
      [sin_phase_offset, temp, results(4)] = utpar_get({sin_args, 'phase_offset'});
      if ~isempty(find(results ~= 0)),
        utlog('error getting arguments for sinusoid source', {'error', ut_log_group});
        error('error getting arguments for sinusoid source');
      end
                
      utlog(['adding sinusoid'], {ut_log_group});
      sinusoid              = sin_amplitude * sin(sin_phase_offset+(sin_cycles/sin_period*2*pi)*[0:vec_len-1])';
      
      data                  = data + sinusoid;      

    elseif strcmp(src_type, 'impulse'),
      impulse_args = {src_args{:}, 'defaults', impulse_defaults};
      [impulse_type, temp, results(1)]      = utpar_get({impulse_args, 'type'});
      [impulse_offset, temp, results(2)]    = utpar_get({impulse_args, 'offset'});
      [impulse_period, temp, results(3)]    = utpar_get({impulse_args, 'period'});
      [impulse_amplitude, temp, results(4)] = utpar_get({impulse_args, 'amplitude'});
      if ~isempty(find(results ~= 0)),
        utlog('error getting arguments for impulse source', {'error', ut_log_group});
        error('error getting arguments for impulse source');
      end
                
      utlog(['adding impulse at offset ',num2str(impulse_offset)], {ut_log_group});
      impulse = zeros(vec_len, 1);
      impulse(impulse_offset+1) = impulse_amplitude; 

      if strcmp(impulse_type, 'periodic'),
        periods = max(1, floor((vec_len-impulse_offset)/impulse_period));
        utlog(['making ', num2str(periods), ' periods'], {ut_log_group});
        impulse = repmat(impulse, periods, 1);
      end
      data                  = data + impulse;     
      
 
    else,
      utlog(['unrecognised source type ''', src_type, ''''], {'error', ut_log_group});
      error(['unrecognised source type ''', src_type, '''']);
    end

  end %for

  result = 0;

  utlog('exiting utdata_gen',{'trace', ut_log_group});
end %function
