function evals = evaluateAllActions(actions, nominal, horizon_s, uncertainty, n_samples, seed)
%EVALUATEALLACTIONS Per-action R_D(a,tau) and cost. Now uses
%   actionNoiseSigma (per-action noise) -- see actionNoiseSigma.m.

if nargin < 5 || isempty(n_samples), n_samples = 300; end
if nargin < 6 || isempty(seed), seed = 0; end

n = numel(actions);

for i = 1:n
    rng(seed + 1000 + i);
    samples = sampleFutureComm(nominal, horizon_s, uncertainty, n_samples);

    matches = 0;
    for k = 1:n_samples
        c = samples(k);

        costs = zeros(1, n);
        for j = 1:n
            sigma_j = actionNoiseSigma(actions(j), c, uncertainty);
            costs(j) = decisionCost(actions(j), c) + sigma_j * randn();
        end

        [~, idx] = min(costs);
        if strcmp(actions(idx).name, actions(i).name)
            matches = matches + 1;
        end
    end

    evals(i).name = actions(i).name;
    evals(i).cost = decisionCost(actions(i), nominal);
    evals(i).r_d = matches / n_samples;
    evals(i).action = actions(i);
end
end