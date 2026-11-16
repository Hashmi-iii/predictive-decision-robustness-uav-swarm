%EXP8_ABLATION_STUDY
%   Experimental Scenario 12: remove one factor at a time from the full
%   (Model E) feature set and measure the AUC drop. A component that
%   barely changes AUC when removed isn't pulling its weight; a component
%   whose removal causes a big drop is empirically justified.
%
%   Ablations here cover the FEATURE-LEVEL components (M_D, topology,
%   U_C, horizon tau). The CONTROLLER-LEVEL ablations from the spec
%   (A5: remove robustness constraint, A6: remove decision-regret) are
%   effectively what exp3_controller_comparison.m already tests by
%   comparing nominal vs constrained vs penalty controllers -- see that
%   script's output alongside this one for the full ablation picture.
%
%   REQUIRES: Statistics and Machine Learning Toolbox (fitglm, perfcurve).

clear; clc;
rng(321);

n_total = 600;
horizon_choices = [1, 3, 5, 10];

X = zeros(n_total, 8);  % pl, delay, aoi, snr, topo_density, margin, uncertainty, horizon
y = zeros(n_total, 1);

for t = 1:n_total
    pl = rand() * 0.5;
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

fprintf('Generated %d trials. Switch rate: %.1f%%\n\n', n_total, 100 * mean(y));

nTrain = round(0.7 * n_total);
idx = randperm(n_total);
trainIdx = idx(1:nTrain);
testIdx = idx(nTrain+1:end);
Xtrain = X(trainIdx, :); ytrain = y(trainIdx);
Xtest = X(testIdx, :);   ytest = y(testIdx);

fullCols = 1:8;  % comm(1-4) + topology(5) + margin(6) + uncertainty(7) + horizon(8)

ablations = struct( ...
    'name', {'Full model (E)', 'A1: remove margin M_D', 'A2: remove topology G_t', ...
              'A3: remove uncertainty U_C', 'A4: remove horizon tau'}, ...
    'dropCol', {[], 6, 5, 7, 8});

fprintf('%-28s%10s%12s\n', 'Ablation', 'AUC', 'Delta AUC');
aucVals = zeros(1, numel(ablations));

for ai = 1:numel(ablations)
    cols = setdiff(fullCols, ablations(ai).dropCol);
    mdl = fitglm(Xtrain(:, cols), ytrain, 'Distribution', 'binomial');
    scores = predict(mdl, Xtest(:, cols));
    [~, ~, ~, AUC] = perfcurve(ytest, scores, 1);
    aucVals(ai) = AUC;

    if ai == 1
        fprintf('%-28s%10.3f%12s\n', ablations(ai).name, AUC, '--');
        fullAUC = AUC;
    else
        fprintf('%-28s%10.3f%12.3f\n', ablations(ai).name, AUC, AUC - fullAUC);
    end
end

fprintf('\nInterpretation: a large NEGATIVE delta means removing that\n');
fprintf('component hurt prediction a lot -- i.e. it is empirically\n');
fprintf('justified. A delta near zero means that component was not\n');
fprintf('pulling its weight in this setup.\n');

figure('Color', 'w');
bar(aucVals, 'FaceColor', [0.06 0.43 0.34]);
set(gca, 'XTickLabel', {ablations.name}, 'XTickLabelRotation', 20);
ylabel('Held-out AUC');
title('Ablation study: feature-level components');
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
saveas(gcf, fullfile(outDir, 'exp8_ablation_study.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp8_ablation_study.png'));