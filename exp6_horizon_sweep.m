%EXP6_HORIZON_SWEEP
%   Experimental Scenario 8: how does R_D degrade as the prediction
%   horizon tau grows? Uses a fixed, moderately-sensitive margin so the
%   horizon effect is visible (a very large margin would stay near R_D=1
%   regardless of tau, masking the effect).

clear; clc;

taus = [1, 3, 5, 10];
nominalComm = struct('packet_loss', 0.20, 'delay_ms', 120, 'aoi_s', 0.4, 'snr_db', 12);
uncertainty = 0.6;
n_samples = 2000;
margin_fixed = 0.5;
actions = makeSyntheticMarginScenario(margin_fixed);
seeds = 0:4;

mean_rd = zeros(size(taus));
std_rd = zeros(size(taus));

fprintf('Fixed: PL=%.0f%%, M_D=%.2f, U_C=%.2f\n\n', ...
    nominalComm.packet_loss * 100, margin_fixed, uncertainty);

for ti = 1:numel(taus)
    tau = taus(ti);
    trial_rd = zeros(size(seeds));
    for si = 1:numel(seeds)
        seed = seeds(si) * 97 + tau * 11;
        res = estimateDecisionRobustness(actions, nominalComm, tau, uncertainty, n_samples, seed);
        trial_rd(si) = res.r_d;
    end
    mean_rd(ti) = mean(trial_rd);
    std_rd(ti) = std(trial_rd);
    fprintf('tau=%2ds   R_D=%.3f  (std=%.3f)\n', tau, mean_rd(ti), std_rd(ti));
end

fprintf('\nInterpretation (Scenario 8): if R_D decreases as tau grows,\n');
fprintf('this confirms decision reliability is harder to predict further\n');
fprintf('into the future -- expected, but must be empirically confirmed.\n');

figure('Color', 'w');
errorbar(taus, mean_rd, std_rd, '-o', 'LineWidth', 2, ...
    'Color', [0.06 0.43 0.34], 'MarkerFaceColor', [0.06 0.43 0.34]);
xlabel('Prediction horizon  \tau (s)');
ylabel('Decision robustness  R_D');
title(sprintf('R_D vs prediction horizon (fixed PL=%.0f%%, M_D=%.2f)', ...
    nominalComm.packet_loss * 100, margin_fixed));
ylim([0 1.02]);
grid on;

outDir = fullfile(pwd, 'outputs');
if ~exist(outDir, 'dir')
    [ok, msg] = mkdir(outDir);
    if ~ok
        warning('Could not create outputs folder (%s). Saving to current folder instead.', msg);
        outDir = pwd;
    end
end
saveas(gcf, fullfile(outDir, 'exp6_horizon_sweep.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp6_horizon_sweep.png'));