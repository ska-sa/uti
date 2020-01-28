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

function[dout] = pfb_fir(n_taps, fft_stages, window_type, fwidth, din),
  dout = [];

  % determine fir coefficients
  alltaps = n_taps*2^fft_stages;
  coeffs = window(window_type, alltaps)' .* sinc((fwidth*([0:alltaps-1]/(2^fft_stages)-n_taps/2)));

  % cut off any excess data
  din = din(1:floor(length(din)/(2^fft_stages))*(2^fft_stages));

  for index = 0:((length(din)/(2^fft_stages))-(n_taps-1))-1,
    unsummed = din(index*(2^fft_stages)+1:(index+n_taps)*(2^fft_stages)).*coeffs;
    summed = sum(reshape(unsummed, 2^fft_stages, n_taps)');

    dout(index*(2^fft_stages)+1:(index+1)*(2^fft_stages),1) = summed;
  end %for

end %function

