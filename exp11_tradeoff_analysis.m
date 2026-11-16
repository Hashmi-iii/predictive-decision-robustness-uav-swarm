%EXP11_TRADEOFF_ANALYSIS  (EXPLORATORY / INCONCLUSIVE -- single seed, non-monotone,
%   achieved R_D varies only ~0.57-0.62 across R_min; do NOT present as a clean trade-off
%   curve. exp13/exp13b are the reliable controller evidence.)
%   Section 45: R_D=1 is not free. Sweeps R_min in the constrained
%   controller and plots mean decision regret (mission performance proxy)
%   against achieved R_D, showing the trade-off curve -- the goal is NOT
%   R_D=1 at any cost, but an acceptable point on this curve.

clear; clc;
rng(77);

actions = defaultActionSet();
n_trials = 80;
horizon_s = 3.0;
uncertainty = 0.6;

r_min_values = [0.0, 0.3, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95];

mean_regret = zeros(size(r_min_values));
mean_achieved_rd = zeros(size(r_min_values));

for ri = 1:numel(r_min_values)
    r_min = r_min_values(ri);
    regrets = zeros(1, n_trials);
    achieved_rd = zeros(1, n_trials);

    for t = 1:n_trials
        pl = rand() * 0.45;
        nominalComm = struct( ...
            'packet_loss', pl, ...
            'delay_ms', 20 + rand() * 380, ...
            'aoi_s', 0.05 + rand() * 1.15, ...
            'snr_db', rand() * 20);

        evals = evaluateAllActions(actions, nominalComm, horizon_s, uncertainty, 200, ri * 1000 + t);
        pick = selectConstrained(evals, r_min);

        rng(50000 + ri * 1000 + t);
        trueFutureArr = sampleFutureComm(nominalComm, horizon_s, uncertainty, 1);
        trueFuture = trueFutureArr(1);

        regrets(t) = decisionRegret(actions, trueFuture, pick.action);
        achieved_rd(t) = pick.r_d;
    end

    mean_regret(ri) = mean(regrets);
    mean_achieved_rd(ri) = mean(achieved_rd);
    fprintf('R_min=%.2f  ->  mean achieved R_D=%.3f   mean regret=%.4f\n', ...
        r_min, mean_achieved_rd(ri), mean_regret(ri));
end

fprintf('\nInterpretation: as R_min rises, achieved R_D should rise too,\n');
fprintf('but regret (mission cost penalty) should also rise -- that''s the\n');
fprintf('trade-off. The right operating point is wherever regret is still\n');
fprintf('acceptable for your mission, not necessarily the highest R_D.\n');

figure('Color', 'w');
plot(mean_achieved_rd, mean_regret, 'o', 'Color', [0.06 0.43 0.34], ...
    'LineWidth', 2, 'MarkerFaceColor', [0.06 0.43 0.34]);
for ri = 1:numel(r_min_values)
    text(mean_achieved_rd(ri), mean_regret(ri), sprintf('  R_{min}=%.2f', r_min_values(ri)), ...
        'FontSize', 8);
end
xlabel('Mean achieved decision robustness  R_D');
ylabel('Mean decision regret  E_D  (mission-performance PROXY)');
title('Exploratory: regret proxy vs achieved R_D across R_{min} (single seed)');
grid on;

outDir = fullfile(pwd, 'outputs');
if ~exist(outDir, 'dir')
    [ok, msg] = mkdir(outDir);
    if ~ok
        warning('Could not create outputs folder (%s). Saving to current folder instead.', msg);
        outDir = pwd;
    end
end
saveas(gcf, fullfile(outDir, 'exp11_tradeoff.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp11_tradeoff.png'));