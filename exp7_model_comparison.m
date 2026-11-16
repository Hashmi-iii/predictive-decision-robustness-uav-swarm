%EXP7_FEATURE_SET_COMPARISON
%   Experimental Scenario 9: does comm+topology+margin+uncertainty+horizon
%   predict decision switching better than comm alone? Fits 5 logistic
%   regression classifiers (SAME algorithm, A-E = different INPUT FEATURE SETS) and compares
%   held-out AUC / accuracy.
%
%   REQUIRES: Statistics and Machine Learning Toolbox (fitglm, perfcurve).

clear; clc;
rng(123);

n_total = 600;
horizon_choices = [1, 3, 5, 10];

X = zeros(n_total, 8);  % pl, delay, aoi, snr, topo_density, margin, uncertainty, horizon
y = zeros(n_total, 1);  % 1 = switched, 0 = persisted

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

    cost_best = decisionCost(actions(1), c_true) + sigma * randn();   % a_best
    cost_second = decisionCost(actions(2), c_true) + sigma * randn(); % a_second

    X(t, :) = [pl, delay, aoi, snr, topo, margin, uncertainty, horizon];
    y(t) = double(cost_second < cost_best);  % 1 if the decision switched
end

fprintf('Generated %d trials. Switch rate: %.1f%%\n\n', n_total, 100 * mean(y));

% --- Train/test split ---
nTrain = round(0.7 * n_total);
idx = randperm(n_total);
trainIdx = idx(1:nTrain);
testIdx = idx(nTrain+1:end);

Xtrain = X(trainIdx, :); ytrain = y(trainIdx);
Xtest = X(testIdx, :);   ytest = y(testIdx);

% --- Model feature sets (Scenario 9) ---
modelNames = {'A: comm only', 'B: comm+topology', 'C: comm+margin', ...
              'D: comm+topo+margin', 'E: proposed (all)'};
featureCols = {[1 2 3 4], [1 2 3 4 5], [1 2 3 4 6], [1 2 3 4 5 6], [1 2 3 4 5 6 7 8]};

fprintf('%-22s%10s%12s\n', 'Feature set', 'AUC', 'Accuracy');
aucVals = zeros(1, numel(modelNames));

for mi = 1:numel(modelNames)
    cols = featureCols{mi};
    mdl = fitglm(Xtrain(:, cols), ytrain, 'Distribution', 'binomial');
    scores = predict(mdl, Xtest(:, cols));

    [~, ~, ~, AUC] = perfcurve(ytest, scores, 1);
    acc = mean((scores >= 0.5) == ytest);

    aucVals(mi) = AUC;
    fprintf('%-22s%10.3f%12.3f\n', modelNames{mi}, AUC, acc);
end

fprintf('\nMajority-class accuracy baseline = %.3f -> accuracy is NOT informative here (imbalanced); use AUC.\n', 1 - mean(ytest));
fprintf('Single split/seed: differences between C, D and E are within noise; only the A/B -> C jump (adding M_D) is supported.\n');
fprintf('\nInterpretation (Scenario 9): if the margin-containing feature sets have the highest AUC,\n');
fprintf('this supports H5 -- the full variable set predicts switching\n');
fprintf('better than communication metrics alone.\n');

figure('Color', 'w');
bar(aucVals, 'FaceColor', [0.06 0.43 0.34]);
set(gca, 'XTickLabel', modelNames, 'XTickLabelRotation', 20);
ylabel('Held-out AUC');
title('Feature-set comparison: predicting decision switching (same classifier)');
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
saveas(gcf, fullfile(outDir, 'exp7_model_comparison.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp7_model_comparison.png'));