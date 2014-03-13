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

function casper_pfb_dc_channel_response_plots(varargin)

  ut_log_group = 'casper_pfb_dc_channel_response_plots_debug';

  utlog('entering', {'trace', ut_log_group});

  result = -1; 
  data = []; 

  defaults = { ...
    'dc_powers', [0, 2^8/2^10],  ...            % dc power to added to input sinusoid
    'offset', 0, ...                            % offset of start frequency in fft bins
    'freq_step', 1/25, ...                      % frequency step for each iteration in fraction of an fft_bin
    'span', 2^6, ...                            % frequency span over which to iterate
    'single_channel_index', 5, ...              % single channel index to display
  };

  args = {varargin{:}, 'defaults', defaults};
  [dc_powers, temp, results(1)]                 = utpar_get({args, 'dc_powers'});
  [din, temp, results(2)]                       = utpar_get({args, 'din'});
  [offset, temp, results(3)]                    = utpar_get({args, 'offset'});
  [fs, temp, results(4)]                        = utpar_get({args, 'freq_step'});
  [span, temp, results(5)]                      = utpar_get({args, 'span'});
  [single_channel_index, temp, results(6)]      = utpar_get({args, 'single_channel_index'});

  if ~isempty(find(results ~= 0)),
      utlog('error getting parameters from varargin',{'error', ut_log_group});
      return;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % plot different channel responses %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
  for index = 1:length(din),
    response = din{index};
    figure;
    plot([offset:fs:(offset+span)-fs], 20*log10(response));
    title(['channel responses with ',num2str(dc_powers(index)),' (1 max) power DC component added']); 
    xlabel('FFT bin');
    ylabel('response to input sinusoid (dB)');
    legend_s = {};
    [r,c] = size(response);
    for n = 1:c, legend_s = {legend_s{:}, ['fft bin ',num2str(n),' ']}; end
    legend(legend_s{:});
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % plot single channel overlay %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  figure;
  hold on;
  legend_s = {};
  colours = {'r', 'g', 'b', 'k', 'y'};
  for index = 1:length(din),
    response = din{index};
    plot([offset:fs:(offset+span)-fs], 20*log10(response(:,single_channel_index)),colours{mod(index, length(colours))});
    title(['FFT bin ',num2str(single_channel_index-1),' response']); 
    xlabel('FFT bin');
    ylabel('response to input sinusoid (dB)');
    legend_s{index} = [num2str(dc_powers(index)), ' (1 max) power DC input']; 
  end
  legend(legend_s{:});

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % plot stats for different frequencies %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  figure;
  hold on;
  din_diff = din{length(din)}./din{1};  %it is assumed that reference in din{1} and worst case in din{length(din)}
  [r,c] = size(din_diff);
  plot([offset:fs:(offset+span)-fs], min(20*log10(din_diff(:,6:c)')), 'r^:');
  plot([offset:fs:(offset+span)-fs], max(20*log10(din_diff(:,6:c)')), 'gv:');
  plot([offset:fs:(offset+span)-fs], mean(20*log10(din_diff(:,6:c)')), 'bo:');
  plot([offset:fs:(offset+span)-fs], std(20*log10(din_diff(:,6:c)')), 'r*:');
  title(['Difference in response between ', num2str(dc_powers(length(din))),' and ', num2str(dc_powers(1))]); 
  xlabel('Frequency (fft bin)');
  ylabel('Response to input sinusoid (dB)');
  legend_s = {'min', 'max', 'mean', 'std'}; 
  legend(legend_s{:});

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % plot stats for different fft bin responses %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  figure;
  hold on;
  plot([0:1:c-1], min(20*log10(din_diff)), 'r^:');
  plot([0:1:c-1], max(20*log10(din_diff)), 'gv:');
  plot([0:1:c-1], mean(20*log10(din_diff)), 'bo:');
  plot([0:1:c-1], std(20*log10(din_diff)), 'r*:');
  title(['Difference in FFT bin response']); 
  xlabel('FFT bin');
  ylabel('Response to input sinusoid (dB)');
  legend_s = {'min', 'max'}; 
  legend(legend_s{:});


  
  utlog('exiting',{'trace', ut_log_group});

end %function
