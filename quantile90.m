function q = quantile90(x)
%QUANTILE90  90th percentile without the Statistics Toolbox.
x = sort(x(:));  n = numel(x);
q = x(min(n, max(1, ceil(0.9 * n))));
end
