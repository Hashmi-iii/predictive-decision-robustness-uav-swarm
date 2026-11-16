%EXP12_END_TO_END_INTEGRATION
%   R_MIN lowered to 0.4 based on the breakpoint sweep (exp12b), which
%   found disagreements=0 for R_min<=0.3. Uses the standalone
%   buildJammingTrajectory.m -- make sure that file exists in this folder.

clear; clc;
rng(2024);

actions = defaultActionSet();
T = 40;
horizon_s = 3.0;
uncertainty = 0.6;
R_MIN = 0.4;
n_samples_per_step = 200;

jamStart = 26; jamEnd = 32;

[plTraj, delayTraj, aoiTraj, snrTraj] = buildJammingTrajectory(T);

controllers = {'baseline', 'pdr_uav'};
switches = struct('baseline', 0, 'pdr_uav', 0);
cumCost = struct('baseline', 0, 'pdr_uav', 0);
regretSum = struct('baseline', 0, 'pdr_uav', 0);
rdSeries = struct('baseline', zeros(1, T), 'pdr_uav', zeros(1, T));
costSeries = struct('baseline', zeros(1, T), 'pdr_uav', zeros(1, T));
prevAction = struct('baseline', '', 'pdr_uav', '');
disagreeSteps = [];

for t = 1:T
    nominalComm = struct('packet_loss', plTraj(t), 'delay_ms', delayTraj(t), ...
        'aoi_s', aoiTraj(t), 'snr_db', snrTraj(t));

    evals = evaluateAllActions(actions, nominalComm, horizon_s, uncertainty, ...
        n_samples_per_step, t * 31);

    pickBase = selectNominal(evals);
    pickPDR = selectConstrained(evals, R_MIN);

    if ~strcmp(pickBase.name, pickPDR.name)
        disagreeSteps(end + 1) = t; %#ok<AGROW>
    end

    tNext = min(t + 1, T);
    trueFuture = struct('packet_loss', plTraj(tNext), 'delay_ms', delayTraj(tNext), ...
        'aoi_s', aoiTraj(tNext), 'snr_db', snrTraj(tNext));

    picks = struct('baseline', pickBase, 'pdr_uav', pickPDR);
    for ci = 1:numel(controllers)
        name = controllers{ci};
        pick = picks.(name);

        realizedCost = decisionCost(pick.action, trueFuture);
        cumCost.(name) = cumCost.(name) + realizedCost;
        costSeries.(name)(t) = cumCost.(name);

        regretSum.(name) = regretSum.(name) + decisionRegret(actions, trueFuture, pick.action);
        rdSeries.(name)(t) = pick.r_d;

        if ~isempty(prevAction.(name)) && ~strcmp(pick.name, prevAction.(name))
            switches.(name) = switches.(name) + 1;
        end
        prevAction.(name) = pick.name;
    end
end

fprintf('=== EXP12: End-to-end mission arc (T=%d, jam=%d-%d, R_min=%.2f) ===\n\n', T, jamStart, jamEnd, R_MIN);
fprintf('Timesteps where PDR-UAV disagreed with baseline: %s\n\n', mat2str(disagreeSteps));

fprintf('%-14s%16s%16s%18s%20s\n', 'controller', 'switches', 'mean regret', ...
    'cumulative cost*', 'min R_D in jam');
for ci = 1:numel(controllers)
    name = controllers{ci};
    minRdJam = min(rdSeries.(name)(jamStart:jamEnd));
    fprintf('%-14s%16d%16.4f%18.3f%20.3f\n', name, switches.(name), ...
        regretSum.(name) / T, cumCost.(name), minRdJam);
end
fprintf('\n* mission-performance PROXY from decisionCost(), not real path/energy/time.\n');

figure('Color', 'w');
subplot(3, 1, 1);
plot(1:T, plTraj * 100, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);
hold on; xline(jamStart, ':k', 'HandleVisibility', 'off'); xline(jamEnd, ':k', 'HandleVisibility', 'off'); hold off;
ylabel('Packet loss (%)'); title('Communication trajectory'); grid on;

subplot(3, 1, 2);
plot(1:T, rdSeries.baseline, '-o', 'Color', [0.85 0.35 0.19], 'LineWidth', 1.5, 'MarkerSize', 3, 'DisplayName', 'Baseline');
hold on;
plot(1:T, rdSeries.pdr_uav, '-s', 'Color', [0.06 0.43 0.34], 'LineWidth', 1.5, 'MarkerSize', 3, 'DisplayName', 'PDR-UAV');
xline(jamStart, ':k', 'HandleVisibility', 'off'); xline(jamEnd, ':k', 'HandleVisibility', 'off'); hold off;
ylabel('Achieved R_D'); ylim([0 1.02]); legend('Location', 'southwest'); grid on;

subplot(3, 1, 3);
plot(1:T, costSeries.baseline, '-o', 'Color', [0.85 0.35 0.19], 'LineWidth', 1.5, 'MarkerSize', 3, 'DisplayName', 'Baseline');
hold on;
plot(1:T, costSeries.pdr_uav, '-s', 'Color', [0.06 0.43 0.34], 'LineWidth', 1.5, 'MarkerSize', 3, 'DisplayName', 'PDR-UAV');
xline(jamStart, ':k', 'HandleVisibility', 'off'); xline(jamEnd, ':k', 'HandleVisibility', 'off'); hold off;
xlabel('Timestep'); ylabel('Cumulative cost (proxy)'); legend('Location', 'northwest'); grid on;

sgtitle('EXP12: baseline vs PDR-UAV (R_{min}=0.4) -- curves coincide: no controller benefit');

outDir = fullfile(pwd, 'outputs');
if ~exist(outDir, 'dir'), mkdir(outDir); end
saveas(gcf, fullfile(outDir, 'exp12_end_to_end.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp12_end_to_end.png'));