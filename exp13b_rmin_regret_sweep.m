%EXP13B_RMIN_REGRET_SWEEP
%   Was R_min=0.4 simply the wrong choice? Sweeps R_min across its full
%   range and reports mean regret at each, to check whether ANY threshold
%   would have beaten baseline on this action set -- not just the one we
%   picked from the earlier disagreement-count breakpoint.

clear; clc;

actions = defaultActionSet();
horizon_s = 3.0;
uncertainty = 0.6;
n_trials = 30;
N_SEEDS = 5;

r_min_values = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];

baselineRegret = zeros(1, N_SEEDS);
regretByRmin = zeros(numel(r_min_values), N_SEEDS);

for s = 1:N_SEEDS
    rng(1000 * s + 7);
    rBase = zeros(1, n_trials);
    rCon = zeros(numel(r_min_values), n_trials);

    for t = 1:n_trials
        pl_t = rand() * 0.45;
        nominalComm = struct('packet_loss', pl_t, 'delay_ms', 20 + rand() * 380, ...
            'aoi_s', 0.05 + rand() * 1.15, 'snr_db', rand() * 20);
        evals = evaluateAllActions(actions, nominalComm, horizon_s, uncertainty, 150, s * 500 + t);
        pickBase = selectNominal(evals);

        rng(90000 * s + t);
        trueFutureArr = sampleFutureComm(nominalComm, horizon_s, uncertainty, 1);
        trueFuture = trueFutureArr(1);
        rBase(t) = decisionRegret(actions, trueFuture, pickBase.action);

        for ri = 1:numel(r_min_values)
            pickCon = selectConstrained(evals, r_min_values(ri));
            rCon(ri, t) = decisionRegret(actions, trueFuture, pickCon.action);
        end
    end
    baselineRegret(s) = mean(rBase);
    regretByRmin(:, s) = mean(rCon, 2);
end

fprintf('%-10s%16s\n', 'R_min', 'mean regret (5 seeds)');
fprintf('%-10s%16.4f   <- baseline\n', 'n/a', mean(baselineRegret));
for ri = 1:numel(r_min_values)
    fprintf('%-10.2f%16.4f\n', r_min_values(ri), mean(regretByRmin(ri, :)));
end

fprintf('\nInterpretation: if EVERY R_min row is >= baseline, no fixed\n');
fprintf('threshold helps on this action set -- confirms the earlier finding\n');
fprintf('is about the action/cost model, not a badly chosen R_min. If some\n');
fprintf('row beats baseline, that value should replace 0.4 going forward.\n');