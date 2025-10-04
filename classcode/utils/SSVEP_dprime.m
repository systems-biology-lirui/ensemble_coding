function dprime = SSVEP_dprime(noise,signal)
% 输入：
%   trial*coil*2(6.25hzhe 25hz)
[~,n_coils,n_frequence] = size(noise);
dprime = zeros(n_frequence,n_coils);
for i = 1:n_frequence
    for coil = 1:n_coils
        currentsignal = squeeze(signal(:,coil,i));
        currentnoise = squeeze(noise(:,coil,i));
        mu_signal = mean(currentsignal);
        mu_noise = mean(currentnoise);

        var_signal = var(currentsignal);
        var_noise = var(currentnoise);

        dprime(i,coil) = (mu_signal - mu_noise) / sqrt((var_signal + var_noise) / 2);
    end
end