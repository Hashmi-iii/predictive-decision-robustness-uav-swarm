%EXP1_MARGIN_SWEEP  Stage 3 checkpoint: does M_D up => R_D up?

clear; clc;

margins = [0.05, 0.1, 0.25, 0.5, 1.0, 2.0, 3.0];
nominalComm = struct('packet_loss', 0.20, 'delay_ms', 120, 'aoi_s', 0.4, 'snr_db', 12);
horizon_s = 3.0;
uncertainty = 0.6;
n_samples = 2000;
seeds = 0:4;

mean_rd = zeros(size(margins));
std_rd = zeros(size(margins));

for mi = 1:numel(margins)
    m = margins(mi);
    actions = makeSyntheticMarginScenario(m);

    trial_rd = zeros(size(seeds));
    for si = 1:numel(seeds)
        seed = seeds(si) * 97 + round(m * 1000);
        res = estimateDecisionRobustness(actions, nominalComm, horizon_s, uncertainty, n_samples, seed);
        trial_rd(si) = res.r_d;
    end

    mean_rd(mi) = mean(trial_rd);
    std_rd(mi) = std(trial_rd);

    fprintf('M_D=%5.2f  R_D=%.3f  (std=%.3f)  P_switch=%.3f\n', ...
        m, mean_rd(mi), std_rd(mi), 1 - mean_rd(mi));
end

figure('Color', 'w');
errorbar(margins, mean_rd, std_rd, '-o', 'LineWidth', 2, ...
    'Color', [0.06 0.43 0.34], 'MarkerFaceColor', [0.06 0.43 0.34]);
xlabel('Decision margin  M_D');
ylabel('Decision robustness  R_D');
title(sprintf('Checkpoint experiment: M_D up => R_D up\n(PL=%.0f%%, horizon=%.0fs, U_C=%.2f)', ...
    nominalComm.packet_loss * 100, horizon_s, uncertainty));
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
saveas(gcf, fullfile(outDir, 'exp1_margin_vs_rd.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp1_margin_vs_rd.png'));