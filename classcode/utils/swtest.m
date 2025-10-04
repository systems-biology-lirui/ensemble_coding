function [H, pValue, W] = swtest(x, alpha)
    % Shapiro-Wilk 正态性检验的简化实现
    x = x(:);
    n = length(x);
    x = sort(x);
    m = norminv(((1:n)' - 0.375) / (n + 0.25));
    W = (m' * x)^2 / ((x - mean(x))' * (x - mean(x)));
    pValue = 1 - chi2cdf(-n * log(W), 1);
    H = pValue < alpha;
end