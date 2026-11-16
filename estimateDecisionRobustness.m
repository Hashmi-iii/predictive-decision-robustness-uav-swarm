function result = estimateDecisionRobustness(actions, nominal, horizon_s, uncertainty, n_samples, seed)
%ESTIMATEDECISIONROBUSTNESS Monte Carlo uncertainty propagation -> R_D.
%   Now uses actionNoiseSigma (per-action noise) instead of a single
%   shared sigma -- see actionNoiseSigma.m for why this matters.

if nargin < 5 || isempty(n_samples), n_samples = 500; end
if nargin < 6 || isempty(seed), seed = 0; end

rng(seed);

[aStar, ~, margin] = bestActionAndMargin(actions, nominal);
futureSamples = sampleFutureComm(nominal, horizon_s, uncertainty, n_samples);

n = numel(actions);
matches = 0;

for k = 1:n_samples
    c = futureSamples(k);

    noisyCosts = zeros(1, n);
    for i = 1:n
        sigma_i = actionNoiseSigma(actions(i), c, uncertainty);
        noisyCosts(i) = decisionCost(actions(i), c) + sigma_i * randn();
    end

    [~, idx] = min(noisyCosts);
    if strcmp(actions(idx).name, aStar.name)
        matches = matches + 1;
    end
end

result.action_name = aStar.name;
result.margin = margin;
result.p_switch = 1.0 - matches / n_samples;
result.r_d = matches / n_samples;
result.n_samples = n_samples;
end