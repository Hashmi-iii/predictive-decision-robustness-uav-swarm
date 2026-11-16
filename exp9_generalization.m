%EXP9_GENERALIZATION_TO_UNSEEN_PL_RANGE
%   SCOPE: supports generalization to the TESTED unseen packet-loss range only
%   (30-60%), not to arbitrary unseen conditions.
%
%   Experimental Scenario 13: train Model E on mild conditions
%   (PL <= 30%), test on unseen severe conditions (PL > 30%). A large
%   AUC drop on the unseen regime means the model isn't generalizing --
%   an important failure mode to catch before claiming this works broadly.
%
%   REQUIRES: Statistics and Machine Learning Toolbox (fitglm, perfcurve).

clear; clc;
rng(654);

n_total = 900;
horizon_choices = [1, 3, 5, 10];

X = zeros(n_total, 8);
y = zeros(n_total, 1);

for t = 1:n_total
    pl = rand() * 0.6;   % wider range than exp7/exp8 so both regimes are populated
    delay = rand() * 400;
    aoi = rand() * 1.5;
    snr = rand() * 20;
    topo = rand();
    margin = 0.02 + rand() * 3.0;
    uncertainty = rand();
    horizon = horizon_choices(randi(numel(horizon_choices)));

    comm = struct('packet_loss', pl, 'delay_ms', delay, 'aoi_s', aoi, 'snr_db', snr);
    actions = makeSyntheticMarginScenario(margin);

    topoFactor = 2.2 - 1.4 * topo;

    futureArr = sampleFutureComm(comm, horizon, uncertainty, 1);
    c_true = futureArr(1);
    sigma = observationNoiseSigma(c_true, uncertainty) * topoFactor;

    cost_best = decisionCost(actions(1), c_true) + sigma * randn();
    cost_second = decisionCost(actions(2), c_true) + sigma * randn();

    X(t, :) = [pl, delay, aoi, snr, topo, margin, uncertainty, horizon];
    y(t) = double(cost_second < cost_best);
end

seenIdx = X(:, 1) <= 0.30;
unseenIdx = X(:, 1) > 0.30;

fprintf('Seen regime (PL<=30%%): %d trials, switch rate %.1f%%\n', ...
    sum(seenIdx), 100 * mean(y(seenIdx)));
fprintf('Unseen regime (PL>30%%): %d trials, switch rate %.1f%%\n\n', ...
    sum(unseenIdx), 100 * mean(y(unseenIdx)));

Xseen = X(seenIdx, :); yseen = y(seenIdx);
Xunseen = X(unseenIdx, :); yunseen = y(unseenIdx);

% Train/test split WITHIN the seen regime, for an in-distribution baseline
nTrain = round(0.7 * size(Xseen, 1));
idx = randperm(size(Xseen, 1));
trainIdx = idx(1:nTrain);
testInSeenIdx = idx(nTrain+1:end);

mdl = fitglm(Xseen(trainIdx, :), yseen(trainIdx), 'Distribution', 'binomial');

scoresInSeen = predict(mdl, Xseen(testInSeenIdx, :));
[~, ~, ~, aucInSeen] = perfcurve(yseen(testInSeenIdx), scoresInSeen, 1);

scoresUnseen = predict(mdl, Xunseen);
[~, ~, ~, aucUnseen] = perfcurve(yunseen, scoresUnseen, 1);

fprintf('AUC on held-out SEEN-regime data:   %.3f\n', aucInSeen);
fprintf('AUC on UNSEEN-regime data (PL>30%%): %.3f\n', aucUnseen);
fprintf('Generalization gap: %.3f\n\n', aucInSeen - aucUnseen);

if (aucInSeen - aucUnseen) > 0.15
    fprintf(['Interpretation: large gap -- the model trained on mild ' ...
        'conditions does NOT generalize well to severe unseen conditions. ' ...
        'This is a real failure mode per Section 63 and should be reported ' ...
        'honestly, not hidden.\n']);
else
    fprintf(['Interpretation: small gap -- the model generalizes reasonably ' ...
        'well from mild to severe unseen conditions.\n']);
end

figure('Color', 'w');
bar([aucInSeen, aucUnseen], 'FaceColor', [0.06 0.43 0.34]);
set(gca, 'XTickLabel', {'Seen (PL<=30%)', 'Unseen (PL>30%)'});
ylabel('AUC');
title('Generalization to unseen PL range (train PL<=30%, test PL>30%)');
ylim([0 1]);
grid on;

outDir = fullfile(pwd, 'outputs');
if ~exist(outDir, 'dir')
    [ok, msg] = mkdir(outDir);
    if ~ok
        warning('Could not create outputs folder (%s). Saving to current folder instead.', msg);
        outDir = pwd;
    end
end
saveas(gcf, fullfile(outDir, 'exp9_generalization.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp9_generalization.png'));