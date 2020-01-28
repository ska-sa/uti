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

function[result] = casper_vs_matlab_basic_plots(varargin)
result = -1; 

%if no block name passed use the default block and version
defaults = { ...
    'data', zeros(1,32), ...
    'data_ref', zeros(1,64), ...
    'input_bit_width', 25, ...  
    'close_all', 'off', ...     %close all figures before starting
    'plots', 'on', ...          %plots
    'debug', 'on', ...          %debug plots and info
}; %defaults

args = {varargin{:}, 'defaults', defaults};
[data, temp, results(1)]            = utpar_get({args, 'data'});
[data_ref, temp, results(2)]        = utpar_get({args, 'data_ref'});
[close_all, temp, results(3)]       = utpar_get({args, 'close_all'});
[input_bit_width, temp, results(6)] = utpar_get({args, 'input_bit_width'});
[plots, temp, results(9)]           = utpar_get({args, 'plots'});
[debug, temp, results(9)]           = utpar_get({args, 'debug'});
if ~isempty(find(results ~= 0)),
  utlog('error getting parameters from varargin',{'error', 'casper_vs_matlab_basic_plots'});
end

if strcmp(close_all, 'on'),
    close all;
end

lsb = 1/2^(input_bit_width-1);

%%%%%%%%%%%%%%
% basic data %
%%%%%%%%%%%%%%

data_real = real(data); 
data_imag = imag(data); 

data_real_mean = mean(mean(data_real));
data_imag_mean = mean(mean(data_imag));
[r,c] = size(data_real);
data_real_std = std(reshape(data_real, r*c, 1));
[r,c] = size(data_imag);
data_imag_std = std(reshape(data_imag, r*c, 1));

data_ref_real = real(data_ref);
data_ref_imag = imag(data_ref);
data_ref_real_mean = mean(mean(data_ref_real));
data_ref_imag_mean = mean(mean(data_ref_imag));
[r,c] = size(data_ref_real);
data_ref_real_std = std(reshape(data_ref_real, r*c, 1));
[r,c] = size(data_ref_imag);
data_ref_imag_std = std(reshape(data_ref_imag, r*c, 1));

diff = data_ref - data;
diff_real = real(diff);
diff_imag = imag(diff);
diff_real_mean = mean(mean(diff_real));
diff_imag_mean = mean(mean(diff_imag));
[r,c] = size(data_ref_real);
diff_real_std = std(reshape(diff_real, r*c, 1));
[r,c] = size(data_ref_imag);
diff_imag_std = std(reshape(diff_imag, r*c, 1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% debug plots if required 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(debug, 'on'),
    if strcmp(plots, 'on'), 
        rp = 3; cp = 2; ip = 1;
        figure;
        subplot(rp,cp,ip);
        plot(mean(data_real'),':o');
        hold on;
        plot(std(data_real'),':*');
        grid on;    
        title(sprintf('real output averaged\n(mean: %.3d, std: %.3d)', data_real_mean, data_real_std));
        legend('mean', 'std');
        xlabel('fft bin');
        ylabel('amplitude');
        ip = ip+1;

        subplot(rp,cp,ip);
        plot(mean(data_imag'),':o');
        hold on;
        plot(std(data_imag'),':*');
        grid on;    
        title(sprintf('imaginary output averaged\n(mean: %.3d, std: %.3d)', data_imag_mean, data_imag_std));
        legend('mean', 'std');
        xlabel('fft bin');
        ylabel('amplitude');
        ip = ip+1;

        subplot(rp,cp,ip);
        plot(mean(data_ref_real'),':o');
        hold on;
        plot(std(data_ref_real'),':*');    
        grid on;    
        title(sprintf('reference real output averaged\n(mean: %.3d std: %.3d', data_ref_real_mean, data_ref_real_std));
        legend('mean', 'std');
        xlabel('fft bin');
        ylabel('amplitude');
        ip = ip+1;

        subplot(rp,cp,ip);
        plot(mean(data_ref_imag'),':o');
        hold on;
        plot(std(data_ref_imag'),':*');    
        grid on;    
        title(sprintf('reference imaginary output averaged\n(mean: %.3d, std: %.3d)', data_ref_imag_mean, data_ref_imag_std));
        legend('mean', 'std');
        xlabel('fft bin');
        ylabel('amplitude');
        ip = ip+1;
    
        %difference from reference
        subplot(rp,cp,ip);
        plot(mean(diff_real'),':o');
        hold on;
        plot(std(diff_real'),':*');    
        grid on;    
        title(sprintf('difference real output averaged\n(mean: %.3d, std: %.3d)', diff_real_mean, diff_real_std));
        legend('mean', 'std');
        xlabel('fft bin');
        ylabel('amplitude');
        ip = ip+1;
        
        subplot(rp,cp,ip);
        plot(mean(diff_imag'),':o');
        hold on;
        plot(std(diff_imag'),':*');    
        grid on;    
        title(sprintf('difference imaginary output averaged\n(mean: %.3d, std: %.3d)', diff_imag_mean, diff_imag_std));
        legend('mean', 'std');
        xlabel('fft bin');
        ylabel('amplitude');
        ip = ip+1;

    else,
        str = sprintf('real output (mean: %.3d, std: %.3d)', data_real_mean, data_real_std);
        disp(str);
        str = sprintf('imaginary output (mean: %.3d, std: %.3d)', data_imag_mean, data_imag_std);
        disp(str);    
        str = sprintf('reference real output (mean: %.3d std: %.3d', data_ref_real_mean, data_ref_real_std);
        disp(str);
        str = sprintf('reference imaginary output (mean: %.3d, std: %.3d)', data_ref_imag_mean, data_ref_imag_std);
        disp(str);

    end
end

%%%%%%%%%%%%%%%
% basic stats 
%%%%%%%%%%%%%%%

% histogram of data of certain amplitude around 0
data_real_lsbs = data_real./lsb;
data_imag_lsbs = data_imag./lsb;

data_ref_real_lsbs = data_ref_real./lsb;
data_ref_imag_lsbs = data_ref_imag./lsb;

n_lsbs = 1000000; %span 
data_real_lsbs_hist = hist(data_real_lsbs, [-n_lsbs/2:n_lsbs/2]);
data_imag_lsbs_hist = hist(data_imag_lsbs, [-n_lsbs/2:n_lsbs/2]);
data_ref_real_lsbs_hist = hist(data_ref_real_lsbs, [-n_lsbs/2:n_lsbs/2]);
data_ref_imag_lsbs_hist = hist(data_ref_imag_lsbs, [-n_lsbs/2:n_lsbs/2]);

[r,c] = size(data_imag_lsbs_hist);
data_imag_lsbs_hist_mean_norm = mean(data_imag_lsbs_hist')/c;
[r,c] = size(data_real_lsbs_hist);
data_real_lsbs_hist_mean_norm = mean(data_real_lsbs_hist')/c;
[r,c] = size(data_ref_imag_lsbs_hist);
data_ref_imag_lsbs_hist_mean_norm = mean(data_ref_imag_lsbs_hist')/c;
[r,c] = size(data_ref_real_lsbs_hist);
data_ref_real_lsbs_hist_mean_norm = mean(data_ref_real_lsbs_hist')/c;

if strcmp(plots,'on'),
    figure;
    rp = 2; cp = 2; ip = 1;

    %histograms of amplitudes of real and imaginary parts
    subplot(rp,cp,ip);
    plot([-n_lsbs/2+1:n_lsbs/2-1], 100*data_real_lsbs_hist_mean_norm(2:n_lsbs));
    title('normalised histogram of real values in output');
    grid on;
    xlabel('amplitude (least sig bits)');
    ylabel('likelihood of occurence (%)');
    ip=ip+1;

    subplot(rp,cp,ip);
    plot([-n_lsbs/2+1:n_lsbs/2-1], 100*data_imag_lsbs_hist_mean_norm(2:n_lsbs));
    grid on;
    title('normalised histogram of imaginary values in output');
    xlabel('amplitude (least sig bits)');
    ylabel('likelihood of occurence (%)');
    ip=ip+1;

    %histograms of amplitudes of reference real and imaginary parts
    subplot(rp,cp,ip);
    plot([-n_lsbs/2+1:n_lsbs/2-1], 100*data_ref_real_lsbs_hist_mean_norm(2:n_lsbs));
    title('normalised histogram of reference real values in output');
    grid on;
    xlabel('amplitude (least sig bits)');
    ylabel('likelihood of occurence (%)');
    ip=ip+1;

    subplot(rp,cp,ip);
    plot([-n_lsbs/2+1:n_lsbs/2-1], 100*data_ref_imag_lsbs_hist_mean_norm(2:n_lsbs));
    grid on;
    title('normalised histogram of reference imaginary values in output');
    xlabel('amplitude (least sig bits)');
    ylabel('likelihood of occurence (%)');

end

%%%%%%%%%%%%%%%%%%%%%%
% difference in lsbs %
%%%%%%%%%%%%%%%%%%%%%%

% difference between reference and data in lsbs

diff_real_lsbs      = diff_real./lsb;
diff_real_lsbs_min  = min(min(diff_real_lsbs));
diff_real_lsbs_max  = max(max(diff_real_lsbs));
diff_real_lsbs_mean = mean(mean(diff_real_lsbs));
[r,c]               = size(diff_real_lsbs);
diff_real_lsbs_std  = std(reshape(diff_real_lsbs,r*c,1));

diff_imag_lsbs      = diff_imag./lsb;
diff_imag_lsbs_min  = min(min(diff_imag_lsbs));
diff_imag_lsbs_max  = max(max(diff_imag_lsbs));
diff_imag_lsbs_mean = mean(mean(diff_imag_lsbs));
[r,c]               = size(diff_imag_lsbs);
diff_imag_lsbs_std  = std(reshape(diff_imag_lsbs,r*c,1));

ref_power       = (abs(data_ref)).^2;
diff_power      = (abs(diff)).^2;
snr             = 10*log10(ref_power - diff_power);
snr_max         = max(snr');
snr_min         = min(snr');
snr_mean        = mean(snr');

diff_phase      = 180/pi*angle(diff);
diff_phase_max  = max(diff_phase');
diff_phase_min  = min(diff_phase');
diff_phase_mean = mean(diff_phase');

if strcmp(plots, 'on'),
    figure;
    rp = 2; cp = 2; ip = 1;
 
    %difference from reference in lsbs
    subplot(rp,cp,ip);
    plot([0:r-1], min(diff_real_lsbs'),':^');
    hold on;
    plot([0:r-1], max(diff_real_lsbs'),':v');
    plot([0:r-1], mean(diff_real_lsbs'),':o');
    plot([0:r-1], std(diff_real_lsbs'),':*');
    
    grid on;
    title(sprintf('difference real output\n(min: %.3d, max: %.3d, mean: %.3d, std: %.3d)', diff_real_lsbs_min, diff_real_lsbs_max, diff_real_lsbs_mean, diff_real_lsbs_std));
    legend('min', 'max', 'mean', 'std');
    xlabel('fft bin');
    ylabel('amplitude (lsbs)');
    ip = ip+1;
    
    subplot(rp,cp,ip);
    plot([0:r-1], min(diff_imag_lsbs'),':^');
    hold on;
    plot([0:r-1], max(diff_imag_lsbs'),':v');
    plot([0:r-1], mean(diff_imag_lsbs'),':o');
    plot([0:r-1], std(diff_imag_lsbs'),':*');    

    grid on;
    title(sprintf('difference imaginary output\n(min: %.3d, max: %.3d, mean: %.3d, std: %.3d)', diff_imag_lsbs_min, diff_imag_lsbs_max, diff_imag_lsbs_mean, diff_imag_lsbs_std));
    legend('min', 'max', 'mean', 'std');
    xlabel('fft bin');
    ylabel('amplitude (lsbs)');
    ip = ip+1;
   
    % power in difference signal (lsbs)
    subplot(rp,cp,ip);
    plot([0:r-1], snr_min,':^');
    hold on;
    plot([0:r-1], snr_max,':v');
    plot([0:r-1], snr_mean,':o');
    grid on;
    title(sprintf('SNR when considering the difference signal as noise\n(min: %.3d, max: %.3d, mean: %.3d)', min(snr_min), max(snr_max), mean(snr_mean)));
    legend('min', 'max', 'mean');
    xlabel('fft bin');
    ylabel('SNR (dB)');
    ip = ip+1;

    % phase in difference
    subplot(rp,cp,ip);
    plot([0:r-1], diff_phase_min,':^');
    hold on;
    plot([0:r-1], diff_phase_max,':v');
    plot([0:r-1], diff_phase_mean,':o');
    grid on;
    title(sprintf('phase in difference signal\n(min: %.3d, max: %.3d, mean: %.3d)', min(diff_phase_min), max(diff_phase_max), mean(diff_phase_mean)));
    legend('min', 'max', 'mean');
    xlabel('fft bin');
    ylabel('phase (degrees)');
    ip = ip+1;

else,
    str = sprintf('difference real output (max: %.3d min: %.3d mean: %.3d std: %.3d', diff_real_max, diff_real_min, diff_real_mean, diff_real_std);
    disp(str);
    str = sprintf('difference imaginary output (max: %.3d min: %.3d mean: %.3d, std: %.3d)', diff_real_max, diff_real_min, diff_imag_mean, diff_imag_std);
    disp(str);
    str = sprintf('difference real output lsbs (mean: %.3d std: %.3d', diff_real_lsbs_mean, diff_real_lsbs_std);
    disp(str);
    str = sprintf('difference imaginary output lsbs (mean: %.3d, std: %.3d)', diff_imag_lsbs_mean, diff_imag_lsbs_std);
    disp(str);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% comparison if used as spectrometer %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if strcmp(plots, 'on'),

    % calculate difference in power as we accumulate
    [r,c] = size(data);

    data_power = (abs(data).^2);
    data_ref_power = (abs(data_ref).^2);
    
    data_ref_power_acc(1:r, 1) = data_ref_power(:,1); 
    data_power_acc(1:r, 1) = data_power(:,1);             % accumulated power  
    acc_lens{1} = '1'; acc_lens_dbl = 1;

    for acc_len = 1:floor(log2(c)),
        data_spectra = data_power(:,1:2^acc_len);
        data_ref_spectra = data_ref_power(:,1:2^acc_len);
        data_ref_power_acc(1:r,acc_len+1) = sum(data_ref_spectra')'; 
        data_power_acc(1:r,acc_len+1) = sum(data_spectra')';             % accumulated power  
        acc_lens{acc_len+1} = num2str(2^acc_len);
        acc_lens_dbl(acc_len+1) = 2^acc_len; 
    end
    
    figure;
    rp = 3; cp = 2; ip = 1;
    
    subplot(rp,cp,ip);
    plot(10*log10(data_ref_power_acc));
    legend(acc_lens);
    grid on;
    title(sprintf('accumulated power in reference'));
    xlabel('fft bin');
    ylabel('power (dBs)');
    ip = ip+1;

    subplot(rp,cp,ip);
    plot(10*log10(data_power_acc));
    legend(acc_lens);
    grid on;
    title(sprintf('accumulated power'));
    xlabel('fft bin');
    ylabel('power (dBs)');
    ip = ip+1;

    %difference from reference for max accumulations with this data   
    subplot(rp,cp,ip);
    max_accs = floor(log2(c));
    diff = 10*(log10(data_ref_power_acc(:,max_accs))-log10(data_power_acc(:,max_accs)));
    plot(diff);
    grid on;
    title(sprintf('difference in power from reference after %d accumulations\n(min: %.3d max: %.3d mean: %.3d)', 2^max_accs, min(diff), max(diff), mean(diff)));
    xlabel('fft bin');
    ylabel('power (dBs)');
    ip = ip+1;

    %total power versus number of accumulations
    data_ref_power_acc_sum = sum(data_ref_power_acc);
    data_power_acc_sum = sum(data_power_acc);

    subplot(rp,cp,ip);
    plot(log2(acc_lens_dbl), 10*log10(data_ref_power_acc_sum'),'*');
    hold on;
    plot(log2(acc_lens_dbl), 10*log10(data_power_acc_sum'),'o');
    grid on;
    legend({'reference', 'ours'});
    title(sprintf('integrated spectral power'));
    xlabel('log2(number of spectra accumulated)');
    ylabel('power (dBs)');
    ip = ip+1;
    
    %difference in total power

    l = length(data_ref_power_acc_sum);
    for index = 1:l-1,
        data_ref_power_acc_sum_diff(index) = 10*log10(data_ref_power_acc_sum(index+1)) - 10*log10(data_ref_power_acc_sum(index));
        data_power_acc_sum_diff(index) = 10*log10(data_power_acc_sum(index+1)) - 10*log10(data_power_acc_sum(index));
    end
    
    subplot(rp,cp,ip);
    plot(log2(acc_lens_dbl(2:l)), data_ref_power_acc_sum_diff, '*');
    hold on;
    plot(log2(acc_lens_dbl(2:l)), data_power_acc_sum_diff', 'o');
    legend({'reference', 'ours'});
    grid on;
    title(sprintf('integrated spectral power difference compared to previous accumulation'));
    xlabel('log2(number of spectra accumulated)');
    ylabel('power difference (dBs)');
    ip = ip+1;
    
    %total power difference from ideal for different accumulation values
    subplot(rp,cp,ip);
    plot(log2(acc_lens_dbl), 10*log10(data_ref_power_acc_sum) - 10*log10(data_power_acc_sum),'o');
    grid on;
    title(sprintf('difference in integrated spectral power from reference'));
    xlabel('log2(number of spectra accumulated)');
    ylabel('power (dBs)');
    ip = ip+1;
     
else,
end

result = 0;
