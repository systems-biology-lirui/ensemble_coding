function d_prime = compute_dprime(signal_value, noise_values)
    mu_signal = mean(signal_value);
    mu_noise = mean(noise_values);
    var_signal = var(signal_value); % 信号方差（单点值，方差为0）
    var_noise = var(noise_values);
    d_prime = (mu_signal - mu_noise) / sqrt((var_signal + var_noise) / 2);
end