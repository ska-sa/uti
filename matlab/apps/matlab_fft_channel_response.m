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

function[dout, result] = fft_channel_response(varargin)
  result = -1;
  ut_log_group = 'fft_channel_response_debug';

  utlog('entering', {'trace', ut_log_group});

  defaults = { ...
    'fft_stages', 5, ...
    'plots', 'on', ...
  };

  args = {varargin{:}, 'defaults', defaults};
  [fft_stages, temp, results(1)]              = utpar_get({args, 'fft_stages'});
  [plots, temp, results(2)]                   = utpar_get({args, 'plots'});

  fs = 1/250;               %frequency separation in fractions of a channel
  span = 2^(fft_stages-1);  %number of channels to iterate through
  amp = 1;                  %amplitude of sinusoid

  if ~isempty(find(results ~= 0)),
      utlog('error getting parameters from varargin',{'error', ut_log_group});
      return;
  end

  response = zeros(2^fft_stages, span/fs);
  
  %get response
  for freq_index = 0:1:span/fs-1,

    %generate data
    f = freq_index*fs;
    sinusoid = amp*sin(2*pi*f/(2^fft_stages)*[0:(2^fft_stages)-1]);
    din = sinusoid;

    % apply fft
    response(:, freq_index+1) = fft(din, 2^fft_stages);
  end %for

  response = response/2^(fft_stages-1); %remove fft gain
  dout = response';                     %reorder so that plot gives response of fft bin

  if strcmp(plots, 'on'),
    %plot results removing gain of fft
    plot([0:fs:span-fs], 20*log10(abs(dout)));
  end

  result = 0;

  utlog('exiting', {'trace', ut_log_group});

end %function

