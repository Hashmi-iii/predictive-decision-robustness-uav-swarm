%EXP12B_RMIN_BREAKPOINT
%   At what R_min does PDR-UAV actually start diverging from baseline?
%   Sweeps R_min across the same 40-step jamming trajectory and counts
%   how many timesteps the two controllers disagree.

clear; clc;

actions = defaultActionSet();
T = 40;
horizon_s = 3.0;
uncertainty = 0.6;
n_samples_per_step = 200;

[plTraj, delayTraj, aoiTraj, snrTraj] = buildJammingTrajectory(T);

r_min_values = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7];

fprintf('%-10s%14s%18s\n', 'R_min', 'disagreements', 'max achievable R_D range seen');
for ri = 1:numel(r_min_values)
    r_min = r_min_values(ri);
    disagreements = 0;
    for t = 1:T
        nominalComm = struct('packet_loss', plTraj(t), 'delay_ms', delayTraj(t), ...
            'aoi_s', aoiTraj(t), 'snr_db', snrTraj(t));
        evals = evaluateAllActions(actions, nominalComm, horizon_s, uncertainty, ...
            n_samples_per_step, t * 31);
        pickBase = selectNominal(evals);
        pickPDR = selectConstrained(evals, r_min);
        if ~strcmp(pickBase.name, pickPDR.name)
            disagreements = disagreements + 1;
        end
    end
    fprintf('%-10.2f%14d\n', r_min, disagreements);
end

fprintf('\nInterpretation: R_min values where disagreements=0 mean PDR-UAV\n');
fprintf('never differs from baseline at that threshold across this whole\n');
fprintf('40-step mission (either because feasible set is always empty, or\n');
fprintf('because the min-cost action always already satisfies it). The\n');
fprintf('first R_min with disagreements>0 is your real operating threshold.\n');