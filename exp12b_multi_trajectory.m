%EXP12B_MULTI_TRAJECTORY
%   exp12 showed a near-null result on ONE fixed jamming trajectory
%   (seed=2024) -- one sample isn't enough to claim anything. This
%   randomizes the ramp timing, jam duration, and peak severity across
%   N_TRAJ trajectories, reruns baseline/constrained/penalty on each, and
%   reports mean +/- std -- same statistical-confidence pattern as exp13,
%   applied to exp12.

clear; clc;

N_TRAJ = 12;
T = 40;
horizon_s = 3.0;
uncertainty = 0.6;
n_samples_per_step = 150;   % lower than exp12's 200 -- N_TRAJ x T x 3 controllers adds up
R_MIN = 0.4;
lambda_r = 1.5;

actions = defaultActionSet();
controllers = {'baseline', 'constrained', 'penalty'};

switches = struct('baseline', zeros(1, N_TRAJ), 'constrained', zeros(1, N_TRAJ), 'penalty', zeros(1, N_TRAJ));
meanRegret = struct('baseline', zeros(1, N_TRAJ), 'constrained', zeros(1, N_TRAJ), 'penalty', zeros(1, N_TRAJ));
minRdJam = struct('baseline', zeros(1, N_TRAJ), 'constrained', zeros(1, N_TRAJ), 'penalty', zeros(1, N_TRAJ));

for trial = 1:N_TRAJ
    [plTraj, delayTraj, aoiTraj, snrTraj, jamStart, jamEnd] = randomJammingTrajectory(T, trial * 777);

    regretSum = struct('baseline', 0, 'constrained', 0, 'penalty', 0);
    rdSeries = struct('baseline', zeros(1, T), 'constrained', zeros(1, T), 'penalty', zeros(1, T));
    swCount = struct('baseline', 0, 'constrained', 0, 'penalty', 0);
    prevAction = struct('baseline', '', 'constrained', '', 'penalty', '');

    for t = 1:T
        nominalComm = struct('packet_loss', plTraj(t), 'delay_ms', delayTraj(t), ...
            'aoi_s', aoiTraj(t), 'snr_db', snrTraj(t));

        evals = evaluateAllActions(actions, nominalComm, horizon_s, uncertainty, ...
            n_samples_per_step, trial * 1000 + t * 31);

        picks = struct( ...
            'baseline', selectNominal(evals), ...
            'constrained', selectConstrained(evals, R_MIN), ...
            'penalty', selectPenalty(evals, lambda_r));

        tNext = min(t + 1, T);
        trueFuture = struct('packet_loss', plTraj(tNext), 'delay_ms', delayTraj(tNext), ...
            'aoi_s', aoiTraj(tNext), 'snr_db', snrTraj(tNext));

        for ci = 1:numel(controllers)
            name = controllers{ci};
            pick = picks.(name);

            regretSum.(name) = regretSum.(name) + decisionRegret(actions, trueFuture, pick.action);
            rdSeries.(name)(t) = pick.r_d;

            if ~isempty(prevAction.(name)) && ~strcmp(pick.name, prevAction.(name))
                swCount.(name) = swCount.(name) + 1;
            end
            prevAction.(name) = pick.name;
        end
    end

    for ci = 1:numel(controllers)
        name = controllers{ci};
        switches.(name)(trial) = swCount.(name);
        meanRegret.(name)(trial) = regretSum.(name) / T;
        minRdJam.(name)(trial) = min(rdSeries.(name)(jamStart:jamEnd));
    end

    fprintf('Trial %2d: jam=[%d-%d] peakPL=%.0f%%  ', trial, jamStart, jamEnd, max(plTraj) * 100);
    for ci = 1:numel(controllers)
        name = controllers{ci};
        fprintf('%s(sw=%d,minRD=%.2f) ', name, switches.(name)(trial), minRdJam.(name)(trial));
    end
    fprintf('\n');
end

fprintf('\n=== Aggregate over %d randomized jamming trajectories ===\n\n', N_TRAJ);
fprintf('%-14s%18s%18s%18s\n', 'controller', 'switches', 'mean regret', 'min R_D in jam');
for ci = 1:numel(controllers)
    name = controllers{ci};
    fprintf('%-14s%9.2f +/-%5.2f%9.4f +/-%6.4f%9.3f +/-%6.3f\n', name, ...
        mean(switches.(name)), std(switches.(name)), ...
        mean(meanRegret.(name)), std(meanRegret.(name)), ...
        mean(minRdJam.(name)), std(minRdJam.(name)));
end

fprintf('\nInterpretation: compare "min R_D in jam" across controllers -- if\n');
fprintf('constrained/penalty show a HIGHER mean than baseline with non-\n');
fprintf('overlapping std, that''s a real reliability improvement during\n');
fprintf('jamming, aggregated over randomized conditions rather than one\n');
fprintf('cherry-picked trajectory. If the means are close, report that\n');
fprintf('honestly -- it would mean this action set/cost model doesn''t give\n');
fprintf('the robustness constraint enough room to matter during severe\n');
fprintf('jamming specifically (consistent with exp12''s single-trajectory\n');
fprintf('diagnostic finding).\n');


function [pl, delay, aoi, snr, jamStart, jamEnd] = randomJammingTrajectory(T, seed)
%RANDOMJAMMINGTRAJECTORY Randomized calm -> ramp -> jam -> recovery
%   pattern: ramp length, jam duration, and peak severity all vary by
%   seed, unlike exp12's fixed schedule.

rng(seed);

calmLen = randi([5, 12]);
rampLen = randi([8, 18]);
jamLen = randi([4, 10]);
peakSeverity = 0.35 + rand() * 0.35;   % 0.35 to 0.70 peak packet loss

calmEnd = calmLen;
rampEnd = min(calmEnd + rampLen, T - jamLen - 2);
rampEnd = max(rampEnd, calmEnd + 1);
jamStart = rampEnd + 1;
jamEnd = min(jamStart + jamLen - 1, T - 1);
jamEnd = max(jamEnd, jamStart);

pl = zeros(1, T);
pl(1:calmEnd) = 0.05;
if rampEnd > calmEnd
    pl(calmEnd + 1:rampEnd) = linspace(0.05, peakSeverity, rampEnd - calmEnd);
end
pl(jamStart:jamEnd) = peakSeverity;
if jamEnd < T
    pl(jamEnd + 1:T) = linspace(peakSeverity, 0.05 + 0.05 * rand(), T - jamEnd);
end

sev = pl / max(pl);
delay = 60 + 340 * sev;
aoi = 0.2 + 1.1 * sev;
snr = 16 - 22 * sev;
end