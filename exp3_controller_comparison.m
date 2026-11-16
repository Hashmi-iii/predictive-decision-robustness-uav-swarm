%EXP3_CONTROLLER_COMPARISON

clear; clc;

rng(42);
actions = defaultActionSet();

n_trials = 60;
horizon_s = 3.0;
uncertainty = 0.6;
r_min = 0.7;
lambda_r = 1.5;

regrets_nominal = zeros(1, n_trials);
regrets_constrained = zeros(1, n_trials);
regrets_penalty = zeros(1, n_trials);
switches_constrained = 0;
switches_penalty = 0;

for t = 1:n_trials
    pl = rand() * 0.45;
    nominalComm = struct( ...
        'packet_loss', pl, ...
        'delay_ms', 20 + rand() * (400 - 20), ...
        'aoi_s', 0.05 + rand() * (1.2 - 0.05), ...
        'snr_db', rand() * 20);

    evals = evaluateAllActions(actions, nominalComm, horizon_s, uncertainty, 250, t);

    pickNom = selectNominal(evals);
    pickCon = selectConstrained(evals, r_min);
    pickPen = selectPenalty(evals, lambda_r);

    rng(1000 + t);
    trueFutureArr = sampleFutureComm(nominalComm, horizon_s, uncertainty, 1);
    trueFuture = trueFutureArr(1);

    regrets_nominal(t) = decisionRegret(actions, trueFuture, pickNom.action);
    regrets_constrained(t) = decisionRegret(actions, trueFuture, pickCon.action);
    regrets_penalty(t) = decisionRegret(actions, trueFuture, pickPen.action);

    if ~strcmp(pickCon.name, pickNom.name)
        switches_constrained = switches_constrained + 1;
    end
    if ~strcmp(pickPen.name, pickNom.name)
        switches_penalty = switches_penalty + 1;
    end
end

fprintf('Over %d random comm conditions (R_min=%.2f, lambda_R=%.2f):\n\n', n_trials, r_min, lambda_r);
fprintf('%-14s%14s%22s\n', 'controller', 'mean regret', 'switches vs nominal');
fprintf('%-14s%14.3f%22d\n', 'nominal', mean(regrets_nominal), 0);
fprintf('%-14s%14.3f%22d\n', 'constrained', mean(regrets_constrained), switches_constrained);
fprintf('%-14s%14.3f%22d\n', 'penalty', mean(regrets_penalty), switches_penalty);

fprintf('\nInterpretation: switches vs nominal counts trials where the robustness-aware controller picked a different action than the plain min-cost baseline.\n');