%EXPADAPTIVESPREAD  Fix for the miscalibrated predictor spread seen in expPredictorLOKO.
%   Static spreads (fitted on training kinds) gave 25-70% coverage for a nominal 90% interval on
%   held-out 'pulsed'. Here the interval is persistence +/- q, where q is the empirical 90% quantile
%   of the |k-step changes| the planner has ALREADY observed in the last W steps (online split-
%   conformal style; uses only past information, no training kinds).
%   Reports coverage AND mean interval width (so a trivially huge interval cannot pass).
%   Output: outputs_addon/adaptive_spread.csv
clear; clc;  addon_paths();
P = swarmParams();  T = 60;  nTest = 10;  W = 15;  ks = [1 3 6];
kinds = {'static_center','pulsed','moving_flank','creeping'};
if ~exist('outputs_addon','dir'), mkdir('outputs_addon'); end
fid = fopen('outputs_addon/adaptive_spread.csv','w');
fprintf(fid,'kind,k,method,coverage,meanWidth,n\n');
fprintf('%-14s %2s %-10s %9s %10s\n','kind','k','method','coverage','meanWidth');
for h = 1:numel(kinds)
    tr = cell(1,0);
    for ki = 1:numel(kinds)
        if ki == h, continue; end
        for s = 1:25
            [jp, jw] = genJammerScenario(kinds{ki}, T, P, 1000*ki + s);
            tr{end+1} = staticCommSeverity(jp, jw, P); %#ok<SAGROW>
        end
    end
    [Xtr, Ytr] = buildXY(tr, max(ks));
    for k = ks
        sigStat = std(Ytr(k,:) - Xtr(1,:));
        cs = 0; ws = 0; ca = 0; wa = 0; n = 0;
        for s = 1:nTest
            [jp, jw] = genJammerScenario(kinds{h}, T, P, 9000 + 17*h + s);
            sev = staticCommSeverity(jp, jw, P);
            for t = (W + k + 1):(T - k)
                truth = sev(t + k);
                idx = (t - W + k):t;                 % past k-step changes already realized by time t
                chg = abs(sev(idx) - sev(idx - k));
                q = quantile90(chg);
                cs = cs + (abs(truth - sev(t)) <= 1.645 * sigStat);  ws = ws + 2 * 1.645 * sigStat;
                ca = ca + (abs(truth - sev(t)) <= q);                wa = wa + 2 * q;
                n = n + 1;
            end
        end
        fprintf('%-14s %2d %-10s %9.3f %10.3f\n', kinds{h}, k, 'static', cs/n, ws/n);
        fprintf('%-14s %2d %-10s %9.3f %10.3f\n', kinds{h}, k, 'adaptive', ca/n, wa/n);
        fprintf(fid,'%s,%d,static,%.4f,%.4f,%d\n',   kinds{h}, k, cs/n, ws/n, n);
        fprintf(fid,'%s,%d,adaptive,%.4f,%.4f,%d\n', kinds{h}, k, ca/n, wa/n, n);
    end
end
fclose(fid);
fprintf('\nSaved outputs_addon/adaptive_spread.csv\n');
