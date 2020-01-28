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

function[dout, result] = pfb_channel_response(varargin)
  ut_log_group = 'pfb_channel_response_debug';

  utlog('entering', {'trace', ut_log_group});

  defaults = { ...
    'n_taps', 4, ...
    'fft_stages', 6, ...
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

  offset = 0;
  fs = 1/100;               %frequency separation in fractions of a channel
  span = 8; %2^(fft_stages-1);  %number of channels to iterate through
  amp = 0.5;                  %amplitude of sinusoid
  noise_power = 0; %1/2^13;     

  if ~isempty(find(results ~= 0)),
      utlog('error getting parameters from varargin',{'error', ut_log_group});
      return;
  end

  response = zeros(2^fft_stages, (span-offset)/fs);
  
  %get response
  for freq_index = offset/fs:1:(offset+span)/fs-1,

    %generate data
    f = freq_index*fs;
    noise = noise_power*randn(1, 2^fft_stages*n_taps);
    sinusoid = amp*sin(2*pi*f/(2^fft_stages)*[0:(2^fft_stages*n_taps)-1]);
    din = noise+sinusoid;

    % apply fir
    fir_dout = pfb_fir(n_taps, fft_stages, window_type, fwidth, din);

    % apply fft to output of fir
    response(:, (freq_index-offset/fs)+1) = fft(fir_dout, 2^fft_stages);

  end %for
  
  %remove fft gain
  response = response./2^(fft_stages-1);
  dout = response'; %flip so that column contains fft bin response

  if strcmp(plots, 'on'),
    %plot results, removing fft gain
    plot([offset:fs:(offset+span)-fs], 20*log10(abs(dout)));
    title(['Channel response']); 
    xlabel('FFT bin');
    ylabel('response to input sinusoid (dB)');
  end

  result = 0;

  utlog('exiting', {'trace', ut_log_group});
end %function

%function[dout] = pfb_fir(n_taps, fft_stages, window_type, fwidth, din)
%
%  % determine fir coefficients
%  alltaps = n_taps*2^fft_stages;
%  coeffs = window(window_type, alltaps)' .* sinc((fwidth*([0:alltaps-1]/(2^fft_stages)-n_taps/2%)));
%
%  % cut off any excess data
%  din = din(1:floor(length(din)/(2^fft_stages))*(2^fft_stages));
%
%  for index = 0:((length(din)/(2^fft_stages))-(n_taps-1))-1,
%    unsummed = din(index*(2^fft_stages)+1:(index+n_taps)*(2^fft_stages)).*coeffs;
%    summed = sum(reshape(unsummed, 2^fft_stages, n_taps)');
%
%    dout(index*(2^fft_stages)+1:(index+1)*(2^fft_stages),1) = summed;
%  end %for
%
%end %function
