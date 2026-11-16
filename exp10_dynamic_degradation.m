%EXP10_DYNAMIC_DEGRADATION
%   Experimental Scenario 14: R_D under time-varying comm degradation,
%   not just a single fixed snapshot. Simulates four trajectories over
%   30 timesteps -- gradual decline, sudden drop, degrade-then-recover,
%   and bursty (short severe spikes) -- and tracks R_D at each step.

clear; clc;

T = 30;
margin_fixed = 0.5;
actions = makeSyntheticMarginScenario(margin_fixed);
horizon_s = 3.0;
uncertainty = 0.6;
n_samples = 800;

pl_gradual = linspace(0.05, 0.45, T);

pl_sudden = 0.05 * ones(1, T);
pl_sudden(T/2:end) = 0.45;

pl_recovery = 0.05 * ones(1, T);
pl_recovery(8:18) = linspace(0.05, 0.45, 11);
pl_recovery(19:end) = linspace(0.45, 0.05, T - 18);

pl_bursty = 0.10 * ones(1, T);
burstIdx = [6 7 15 16 24 25];
pl_bursty(burstIdx) = 0.50;

trajectories = struct( ...
    'name', {'Gradual decline', 'Sudden drop', 'Degrade then recover', 'Bursty spikes'}, ...
    'pl', {pl_gradual, pl_sudden, pl_recovery, pl_bursty});

rd_traj = zeros(numel(trajectories), T);

for tj = 1:numel(trajectories)
    pl_series = trajectories(tj).pl;
    for k = 1:T
        comm = struct('packet_loss', pl_series(k), 'delay_ms', 100, 'aoi_s', 0.3, 'snr_db', 14);
        res = estimateDecisionRobustness(actions, comm, horizon_s, uncertainty, n_samples, tj * 1000 + k);
        rd_traj(tj, k) = res.r_d;
    end
    fprintf('%-22s  min R_D=%.3f  mean R_D=%.3f\n', trajectories(tj).name, ...
        min(rd_traj(tj, :)), mean(rd_traj(tj, :)));
end

fprintf('\nInterpretation: watch WHERE R_D dips lowest relative to the PL\n');
fprintf('curve for each pattern -- e.g. a fragility engine should show R_D\n');
fprintf('dropping sharply during the bursty spikes and recovering fast,\n');
fprintf('vs. tracking the gradual decline more smoothly.\n');

figure('Color', 'w');
colors = [0.06 0.43 0.34; 0.85 0.35 0.19; 0.20 0.40 0.75; 0.55 0.20 0.60];
for tj = 1:numel(trajectories)
    subplot(2, 2, tj);
    yyaxis left
    plot(1:T, trajectories(tj).pl * 100, ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2);
    ylabel('Packet loss (%)');
    ylim([0 55]);
    yyaxis right
    plot(1:T, rd_traj(tj, :), '-o', 'Color', colors(tj, :), 'LineWidth', 1.8, 'MarkerSize', 3);
    ylabel('R_D');
    ylim([0 1.02]);
    title(trajectories(tj).name);
    xlabel('Timestep');
    grid on;
end
sgtitle('R_D under dynamic communication degradation patterns');

outDir = fullfile(pwd, 'outputs');
if ~exist(outDir, 'dir')
    [ok, msg] = mkdir(outDir);
    if ~ok
        warning('Could not create outputs folder (%s). Saving to current folder instead.', msg);
        outDir = pwd;
    end
end
saveas(gcf, fullfile(outDir, 'exp10_dynamic_degradation.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp10_dynamic_degradation.png'));