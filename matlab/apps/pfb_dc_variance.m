% application to determine the Matlab PFB response of noise in the presence of 
% varying DC power

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

function[dout, result] = pfb_dc_variance(varargin)
  ut_log_group = 'pfb_dc_variance_debug';

  utlog('entering', {'trace', ut_log_group});

  defaults = { ...
    'n_taps', 8, ...
    'fft_stages', 13, ...
    'window_type', 'hamming', ...
    'fwidth', 1, ...
    'plots', 'on', ...
  };

  args = {varargin{:}, 'defaults', defaults};
  [n_taps, temp, results(1)]                 = utpar_get({args, 'n_taps'});
  [fft_stages, temp, results(2)]             = utpar_get({args, 'fft_stages'});
  [window_type, temp, results(3)]            = utpar_get({args, 'window_type'});
  [fwidth, temp, results(4)]                 = utpar_get({args, 'fwidth'});
  [plots, temp, results(5)]                  = utpar_get({args, 'plots'});

  if ~isempty(find(results ~= 0)),
      utlog('error getting parameters from varargin',{'error', ut_log_group});
      return;
  end

  dc_powers   = [0, 1/2^10, 4/2^10];
  noise_power = 2^3/2^10;
  run_time    = 10*(10^5);  % TODO base this on noise level to go down to 
  run_time_quantum = 10^5; % max number of values we can safely create at a time

  response = zeros(2^fft_stages, length(dc_powers));

  iterations = ceil(run_time/run_time_quantum);
  utlog(['Require ', num2str(iterations), ' iterations for ',num2str(length(dc_powers)), ' powers'], ut_log_group);

  n_spectra = ceil(run_time_quantum/(2^fft_stages));
  total_time = 0;

  for dc_power_index = 1:length(dc_powers), 
    for iteration_index = 1:iterations,
      utlog(['Iteration ', num2str(iteration_index), ' of ', num2str(iterations),' for power at index ',num2str(dc_power_index), ' of ', num2str(length(dc_powers))], ut_log_group);

      %generate data
      noise = noise_power.*randn(1, n_spectra*(2^fft_stages));
      din = noise+dc_powers(dc_power_index);

      % apply fir
      fir_dout = pfb_fir(n_taps, fft_stages, window_type, fwidth, din);

      n = floor(length(fir_dout)/(2^fft_stages));
      fft_din = reshape(fir_dout(1:n*(2^fft_stages)), 2^fft_stages, n);

      % apply fft to output of fir
      fft_dout = fft(fft_din, 2^fft_stages);
     
      %remove fft gain
      fft_dout = fft_dout./2^(fft_stages-1);
   
      [r,c] = size(fft_dout);
      total_time = total_time + r*c;

      %sum all fft bins together and normalise by the number of vectors we are summing
      fft_dout_sum = sum(abs(fft_dout'))./c;

      %sum power 
      response(:, dc_power_index) = response(:, dc_power_index) + fft_dout_sum';
    end %for
  end %for 
 
  dout = response;
  if strcmp(plots, 'on'),
    figure;
    plot(20*log10(abs(dout)));
    title(['Channel response']); 
    xlabel('FFT bin');
  end

  result = 0;

  utlog('exiting', {'trace', ut_log_group});
end %function

