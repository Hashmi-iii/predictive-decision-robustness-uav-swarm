function [pl, delay, aoi, snr] = buildJammingTrajectory(T)
%BUILDJAMMINGTRAJECTORY Calm -> ramp-up -> OSCILLATING jam -> recovery.
%   The jam window now oscillates near the cost-crossover region instead
%   of sitting at a flat, unambiguous peak -- tests whether disagreement
%   reappears when severity hovers near the ambiguous zone throughout the
%   "jammed" period, not just during the ramp transitions.

pl = zeros(1, T);
pl(1:10) = 0.05;
pl(11:25) = linspace(0.05, 0.45, 15);   % ramp only to ~0.45, not 0.55 -- nearer the crossover
pl(26:32) = 0.45 + 0.08 * sin(2 * pi * (0:6) / 4);  % oscillates 0.37-0.53 within the jam window
pl(33:T) = linspace(0.45, 0.10, T - 32);

sev = pl / max(pl);
delay = 60 + 340 * sev;
aoi = 0.2 + 1.1 * sev;
snr = 16 - 22 * sev;
end