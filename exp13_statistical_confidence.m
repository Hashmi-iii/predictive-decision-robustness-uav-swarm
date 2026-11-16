%EXP13_STATISTICAL_CONFIDENCE  (Part B updated with progress printing)
%   If this stalls or errors, the printed "seed X/8 done" lines will show
%   exactly how far it got before you need to paste the output.

clear; clc;

N_SEEDS = 8;
horizon_s = 3.0;
n_samples = 1500;

fprintf('=== A) Key comparison (exp2, Section 52): State A vs State B, repeated ===\n');
pl = 0.20;
comm = struct('packet_loss', pl, 'delay_ms', 100, 'aoi_s', 0.3, 'snr_db', 14);
stateA = makeSyntheticMarginScenario(2.5);
stateB = makeSyntheticMarginScenario(0.08);

rdA = zeros(1, N_SEEDS);
rdB = zeros(1, N_SEEDS);
for s = 1:N_SEEDS
    resA = estimateDecisionRobustness(stateA, comm, horizon_s, 0.25, n_samples, s * 17);
    resB = estimateDecisionRobustness(stateB, comm, horizon_s, 0.90, n_samples, s * 29);
    rdA(s) = resA.r_d;
    rdB(s) = resB.r_d;
end
fprintf('State A: R_D = %.3f +/- %.3f  (n=%d seeds)\n', mean(rdA), std(rdA), N_SEEDS);
fprintf('State B: R_D = %.3f +/- %.3f  (n=%d seeds)\n', mean(rdB), std(rdB), N_SEEDS);
fprintf('Gap: %.3f\n\n', mean(rdA) - mean(rdB));

fprintf('=== B) Controller comparison (exp3), repeated ===\n');
tic;
actions = defaultActionSet();
n_trials = 30;   % HALVED from 60 -- this is likely why it was slow; raise back once confirmed working
r_min = 0.4;     % updated to match the exp12b breakpoint finding, was 0.7
lambda_r = 1.5;
uncertainty = 0.6;

regretNom = zeros(1, N_SEEDS);
regretCon = zeros(1, N_SEEDS);
regretPen = zeros(1, N_SEEDS);

for s = 1:N_SEEDS
    rng(1000 * s + 42);
    rNom = zeros(1, n_trials); rCon = zeros(1, n_trials); rPen = zeros(1, n_trials);
    for t = 1:n_trials
        pl_t = rand() * 0.45;
        nominalComm = struct('packet_loss', pl_t, 'delay_ms', 20 + rand() * 380, ...
            'aoi_s', 0.05 + rand() * 1.15, 'snr_db', rand() * 20);
        evals = evaluateAllActions(actions, nominalComm, horizon_s, uncertainty, 150, s * 500 + t);
        pickNom = selectNominal(evals);
        pickCon = selectConstrained(evals, r_min);
        pickPen = selectPenalty(evals, lambda_r);

        rng(90000 * s + t);
        trueFutureArr = sampleFutureComm(nominalComm, horizon_s, uncertainty, 1);
        trueFuture = trueFutureArr(1);

        rNom(t) = decisionRegret(actions, trueFuture, pickNom.action);
        rCon(t) = decisionRegret(actions, trueFuture, pickCon.action);
        rPen(t) = decisionRegret(actions, trueFuture, pickPen.action);
    end
    regretNom(s) = mean(rNom);
    regretCon(s) = mean(rCon);
    regretPen(s) = mean(rPen);
    fprintf('  seed %d/%d done (elapsed %.1fs)\n', s, N_SEEDS, toc);
end

fprintf('\nnominal:      mean regret = %.4f +/- %.4f\n', mean(regretNom), std(regretNom));
fprintf('constrained:  mean regret = %.4f +/- %.4f\n', mean(regretCon), std(regretCon));
fprintf('penalty:      mean regret = %.4f +/- %.4f\n\n', mean(regretPen), std(regretPen));

winsConVsNom = sum(regretCon < regretNom);
fprintf('Paired check: constrained beat nominal in %d/%d seed-level runs.\n', winsConVsNom, N_SEEDS);