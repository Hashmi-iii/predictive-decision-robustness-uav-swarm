%EXP12C_TRANSITION_VS_PLATEAU
%   Tests the crossover hypothesis: does PDR-UAV diverge from baseline
%   specifically during severity TRANSITIONS (ramp-up/recovery), not
%   during the sustained jamming PLATEAU?

clear; clc;

actions = defaultActionSet();
T = 40;
horizon_s = 3.0;
uncertainty = 0.6;
n_samples_per_step = 150;
R_MIN = 0.4;

[plTraj, delayTraj, aoiTraj, snrTraj] = buildJammingTrajectory(T);
jamStart = 26; jamEnd = 32;

disagreeTransition = 0;
disagreePlateau = 0;
totalTransitionSteps = 0;
totalPlateauSteps = 0;

for t = 1:T
    nominalComm = struct('packet_loss', plTraj(t), 'delay_ms', delayTraj(t), ...
        'aoi_s', aoiTraj(t), 'snr_db', snrTraj(t));
    evals = evaluateAllActions(actions, nominalComm, horizon_s, uncertainty, ...
        n_samples_per_step, t * 31);
    pickBase = selectNominal(evals);
    pickPDR = selectConstrained(evals, R_MIN);
    disagree = ~strcmp(pickBase.name, pickPDR.name);

    if t >= jamStart && t <= jamEnd
        totalPlateauSteps = totalPlateauSteps + 1;
        disagreePlateau = disagreePlateau + disagree;
    else
        totalTransitionSteps = totalTransitionSteps + 1;
        disagreeTransition = disagreeTransition + disagree;
    end
end

fprintf('Plateau (t=%d-%d):    %d/%d steps disagreed (%.1f%%)\n', ...
    jamStart, jamEnd, disagreePlateau, totalPlateauSteps, 100*disagreePlateau/totalPlateauSteps);
fprintf('Transitions/calm:     %d/%d steps disagreed (%.1f%%)\n', ...
    disagreeTransition, totalTransitionSteps, 100*disagreeTransition/totalTransitionSteps);