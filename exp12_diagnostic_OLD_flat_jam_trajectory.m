%EXP12_DIAGNOSTIC
%   Standalone check: why did baseline and PDR-UAV agree at every step
%   during the jam window in exp12? Prints per-action R_D and cost at
%   each jam-window timestep so we can see whether R_MIN=0.7 ever binds.

clear; clc;

actions = defaultActionSet();
horizon_s = 3.0;
uncertainty = 0.6;
R_MIN = 0.7;
n_samples_per_step = 200;

T = 40;
pl = zeros(1, T);
pl(1:10) = 0.05;
pl(11:25) = linspace(0.05, 0.55, 15);
pl(26:32) = 0.55;
pl(33:T) = linspace(0.55, 0.10, T - 32);
sev = pl / 0.55;
delay = 60 + 340 * sev;
aoi = 0.2 + 1.1 * sev;
snr = 16 - 22 * sev;

jamStart = 26; jamEnd = 32;

for t = jamStart:jamEnd
    nominalComm = struct('packet_loss', pl(t), 'delay_ms', delay(t), ...
        'aoi_s', aoi(t), 'snr_db', snr(t));
    evals = evaluateAllActions(actions, nominalComm, horizon_s, uncertainty, ...
        n_samples_per_step, t * 31);

    fprintf('--- t=%d (PL=%.0f%%) ---\n', t, pl(t) * 100);
    for i = 1:numel(evals)
        fprintf('  %-22s cost=%.3f  R_D=%.3f\n', evals(i).name, evals(i).cost, evals(i).r_d);
    end
    pickBase = selectNominal(evals);
    pickPDR = selectConstrained(evals, R_MIN);
    fprintf('  => baseline picks: %s | pdr_uav picks: %s | R_min feasible set size: %d\n\n', ...
        pickBase.name, pickPDR.name, sum([evals.r_d] >= R_MIN));
end