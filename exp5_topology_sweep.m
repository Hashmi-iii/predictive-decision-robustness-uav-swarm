%EXP5_TOPOLOGY_SWEEP
%   Experimental Scenario 6: does topology change R_D even when comm
%   quality is held fixed?
%
%   NOTE: the base codebase has no explicit topology/graph representation
%   (comm state only tracks per-link PL/delay/AoI/SNR, not redundancy).
%   This script adds a simple topology_density factor (0=fragmented,
%   1=dense/redundant) that scales the effective information noise --
%   denser topology means more redundant paths, so per-action cost
%   estimates average out and are less noisy for the same raw comm
%   quality. This is a deliberately simple stand-in for a real graph
%   model (Module 3's G_t=(V,E_t,W_t)) -- good enough to test H4, not a
%   substitute for eventually modeling the actual multi-UAV graph.

clear; clc;

topology_levels = struct( ...
    'name', {'dense_redundant', 'moderate', 'sparse', 'fragmentation_prone'}, ...
    'density', {0.9, 0.6, 0.3, 0.1});

nominalComm = struct('packet_loss', 0.20, 'delay_ms', 120, 'aoi_s', 0.4, 'snr_db', 12);
horizon_s = 3.0;
uncertainty = 0.6;
n_samples = 2000;
margin_fixed = 0.5;   % moderate margin -- sensitive enough to show topology's effect
actions = makeSyntheticMarginScenario(margin_fixed);

rd_by_topology = zeros(1, numel(topology_levels));

fprintf('Fixed: PL=%.0f%%, M_D=%.2f, U_C=%.2f\n\n', ...
    nominalComm.packet_loss * 100, margin_fixed, uncertainty);

for ti = 1:numel(topology_levels)
    rho = topology_levels(ti).density;
    res = estimateRobustnessWithTopology(actions, nominalComm, horizon_s, ...
        uncertainty, rho, n_samples, ti * 13);
    rd_by_topology(ti) = res;
    fprintf('%-22s density=%.1f  ->  R_D=%.3f\n', topology_levels(ti).name, rho, res);
end

fprintf('\nInterpretation (H4): if R_D varies meaningfully across rows above\n');
fprintf('despite IDENTICAL comm quality (PL=20%% for all), topology has a\n');
fprintf('real effect on decision reliability beyond raw comm metrics.\n');

figure('Color', 'w');
bar(rd_by_topology, 'FaceColor', [0.06 0.43 0.34]);
set(gca, 'XTickLabel', strrep({topology_levels.name}, '_', ' '), 'XTickLabelRotation', 20);
ylabel('Decision robustness  R_D');
title(sprintf('R_D vs topology density (fixed PL=%.0f%%, M_D=%.2f)', ...
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
saveas(gcf, fullfile(outDir, 'exp5_topology_sweep.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp5_topology_sweep.png'));


function r_d = estimateRobustnessWithTopology(actions, nominal, horizon_s, uncertainty, topology_density, n_samples, seed)
%ESTIMATEROBUSTNESSWITHTOPOLOGY Same Monte Carlo logic as
%   estimateDecisionRobustness.m, but scales the per-action noise by a
%   topology factor: dense (density->1) lowers effective noise, sparse
%   (density->0) raises it.

rng(seed);
[aStar, ~, ~] = bestActionAndMargin(actions, nominal);
futureSamples = sampleFutureComm(nominal, horizon_s, uncertainty, n_samples);

topoFactor = 2.2 - 1.4 * topology_density;  % dense(1)->0.8x noise, fragmented(0.1)->~2.06x

n = numel(actions);
matches = 0;

for k = 1:n_samples
    c = futureSamples(k);
    sigma = observationNoiseSigma(c, uncertainty) * topoFactor;

    noisyCosts = zeros(1, n);
    for i = 1:n
        noisyCosts(i) = decisionCost(actions(i), c) + sigma * randn();
    end

    [~, idx] = min(noisyCosts);
    if strcmp(actions(idx).name, aStar.name)
        matches = matches + 1;
    end
end

r_d = matches / n_samples;
end