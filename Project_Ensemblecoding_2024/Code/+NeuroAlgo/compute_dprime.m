function dp = compute_dprime(sig_dist, noise_dist)
    % sig_dist:   [N_samples, nCh] (信号条件下的多次观测值，如 PSD 值)
    % noise_dist: [M_samples, nCh] (噪声条件下的多次观测值)
    % 输出 dp: [1, nCh]
    
    mu_s = mean(sig_dist, 1, 'omitnan');
    mu_n = mean(noise_dist, 1, 'omitnan');
    
    var_s = var(sig_dist, 0, 1, 'omitnan');
    var_n = var(noise_dist, 0, 1, 'omitnan');
    
    % 标准 d' 公式: (u_s - u_n) / sqrt(0.5 * (var_s + var_n))
    pooled_std = sqrt(0.5 * (var_s + var_n));
    
    % 防止分母为0
    pooled_std(pooled_std < 1e-9) = 1e-9;
    
    dp = (mu_s - mu_n) ./ pooled_std;
end