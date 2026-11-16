function make_paper_tables()
%MAKE_PAPER_TABLES  Reads every CSV in outputs_addon/ and writes
%   outputs_addon/paper_tables.md  (markdown tables)  and  outputs_addon/fig_*.png.
%   Each section is skipped with a message if its CSV is missing, so it is safe to run at any time.
%   Run from the project root: addpath('addon'); make_paper_tables
d = 'outputs_addon';
if ~exist(d,'dir'), error('outputs_addon not found: run from the project root.'); end
buf = '';
buf = ad(buf,'# Auto-generated tables (from outputs_addon/*.csv)\n\n');

% ---- 1. verification
T = tryRead(d,'verify_report.csv');
if ~isempty(T)
    buf = ad(buf,'## Script verification\n\n| script | status | seconds | new figures |\n|---|---|---|---|\n');
    for i = 1:height(T), buf = ad(buf,'| %s | %s | %.1f | %d |\n', T.script{i}, T.status{i}, T.seconds(i), T.newFigures(i)); end
    buf = ad(buf,'\n');
end

% ---- 2. calibration
T = tryRead(d,'calibration_summary.csv');
if ~isempty(T)
    buf = ad(buf,'## R_D calibration vs hindsight oracle\n\n| variant | subset | n | mean pred | mean obs | Brier | ECE |\n|---|---|---|---|---|---|---|\n');
    for i = 1:height(T), buf = ad(buf,'| %s | %s | %d | %.3f | %.3f | %.4f | %.4f |\n', T.variant{i}, T.subset{i}, T.n(i), T.meanPred(i), T.meanObs(i), T.brier(i), T.ECE(i)); end
    buf = ad(buf,'\n');
end
B = tryRead(d,'calibration_bins.csv');
if ~isempty(B)
    figure('Visible','off'); hold on; plot([0 1],[0 1],'k--');
    vs = {'base','oraclejam+stateunc_g1'};
    for v = 1:numel(vs)
        m = strcmp(B.variant, vs{v}) & strcmp(B.subset,'all') & B.n > 0;
        plot(B.meanPred(m), B.meanObs(m), '-o', 'DisplayName', vs{v});
    end
    xlabel('predicted R_D'); ylabel('observed oracle-match frequency'); legend('Location','southeast');
    title('Reliability diagram'); grid on; saveas(gcf, fullfile(d,'fig_reliability.png')); close(gcf);
end

% ---- 3. controllers vs nominal
T = tryRead(d,'baselines_paired_vs_nominal.csv');
if ~isempty(T)
    buf = ad(buf,'## Controllers vs nominal (paired, hindsight regret)\n\n| controller | gain | kind | mean regret | diff vs nominal | 95%% CI | W/L/T |\n|---|---|---|---|---|---|---|\n');
    for i = 1:height(T)
        buf = ad(buf,'| %s | %g | %s | %.4f | %.4f | [%.4f, %.4f] | %d/%d/%d |\n', T.controller{i}, T.uncGain(i), T.kind{i}, T.meanRegret(i), T.meanDiffVsNominal(i), T.ci95lo(i), T.ci95hi(i), T.wins(i), T.losses(i), T.ties(i));
    end
    buf = ad(buf,'\n');
    m = strcmp(T.kind,'ALL') & T.uncGain == 0;
    figure('Visible','off');
    dd = T.meanDiffVsNominal(m);  lo = dd - T.ci95lo(m);  hi = T.ci95hi(m) - dd;  nm = T.controller(m);
    bar(dd); hold on; errorbar(1:numel(dd), dd, lo, hi, 'k.');
    set(gca,'XTick',1:numel(nm),'XTickLabel',nm); ylabel('regret difference vs nominal (negative = better)');
    title('Controller comparison, all scenarios'); grid on; saveas(gcf, fullfile(d,'fig_controllers.png')); close(gcf);
end

T = tryRead(d,'expected_vs_robust.csv');
if ~isempty(T)
    buf = ad(buf,'## Robustness rules vs plain expected cost\n\n| config | mean regret | diff vs expected | 95%% CI | W/L/T | runs with different actions |\n|---|---|---|---|---|---|\n');
    for i = 1:height(T), buf = ad(buf,'| %s | %.4f | %.4f | [%.4f, %.4f] | %d/%d/%d | %d |\n', T.config{i}, T.meanRegret(i), T.diffVsExpectedNS40(i), T.ci95lo(i), T.ci95hi(i), T.wins(i), T.losses(i), T.ties(i), T.runsWithDifferentActions(i)); end
    buf = ad(buf,'\n');
end
T = tryRead(d,'stress_sweep.csv');
if ~isempty(T)
    buf = ad(buf,'## Stress sweep\n\n| level | controller | mean regret | diff vs expected | 95%% CI | W/L/T | frac R_D in 0.1-0.9 |\n|---|---|---|---|---|---|---|\n');
    for i = 1:height(T), buf = ad(buf,'| %s | %s | %.4f | %.4f | [%.4f, %.4f] | %d/%d/%d | %.3f |\n', T.level{i}, T.controller{i}, T.meanRegret(i), T.diffVsExpected(i), T.ci95lo(i), T.ci95hi(i), T.wins(i), T.losses(i), T.ties(i), T.fracRdMid(i)); end
    buf = ad(buf,'\n');
end
T = tryRead(d,'large_n.csv');
if ~isempty(T)
    df = T.regretConstrained - T.regretExpected;  n = numel(df);  se = std(df)/sqrt(n);
    w = sum(df < -1e-9);  l = sum(df > 1e-9);
    buf = ad(buf,'## Constrained (R_min 0.8) vs expected, n=%d paired runs\n\nmean diff %.5f, 95%% CI [%.5f, %.5f], wins/losses/ties %d/%d/%d\n\n', n, mean(df), mean(df)-1.96*se, mean(df)+1.96*se, w, l, n-w-l);
end

% ---- 4. timing
T = tryRead(d,'timing.csv');
if ~isempty(T)
    buf = ad(buf,'## Decision latency (this PC; cycle = %d ms)\n\n| method | nSamples | uncGain | median ms | p95 ms | max ms |\n|---|---|---|---|---|---|\n', T.cycle_ms(1));
    for i = 1:height(T), buf = ad(buf,'| %s | %d | %g | %.1f | %.1f | %.1f |\n', T.method{i}, T.nSamples(i), T.uncGain(i), T.median_ms(i), T.p95_ms(i), T.max_ms(i)); end
    buf = ad(buf,'\n');
    m = strcmp(T.method,'MC R_D + regret eval') & T.uncGain == 1;
    figure('Visible','off'); plot(T.nSamples(m), T.median_ms(m), '-o', T.nSamples(m), T.p95_ms(m), '-s'); hold on;
    yline(T.cycle_ms(1),'r--'); legend('median','p95','cycle budget'); xlabel('Monte-Carlo samples'); ylabel('ms'); grid on;
    title('Decision latency'); saveas(gcf, fullfile(d,'fig_timing.png')); close(gcf);
end

% ---- 5. predictors
T = tryRead(d,'predictor_loko.csv');
if ~isempty(T)
    buf = ad(buf,'## Predictors, leave-one-jammer-kind-out\n\n| held-out | model | k | RMSE | coverage of nominal 90%% interval |\n|---|---|---|---|---|\n');
    for i = 1:height(T), buf = ad(buf,'| %s | %s | %d | %.4f | %.3f |\n', T.heldout{i}, T.model{i}, T.k(i), T.rmse(i), T.cov90(i)); end
    buf = ad(buf,'\n');
end
T = tryRead(d,'adaptive_spread.csv');
if ~isempty(T)
    buf = ad(buf,'## Static vs adaptive prediction interval (nominal 90%%)\n\n| held-out | k | method | coverage | mean width |\n|---|---|---|---|---|\n');
    for i = 1:height(T), buf = ad(buf,'| %s | %d | %s | %.3f | %.3f |\n', T.kind{i}, T.k(i), T.method{i}, T.coverage(i), T.meanWidth(i)); end
    buf = ad(buf,'\n');
end

fid = fopen(fullfile(d,'paper_tables.md'),'w');
if fid < 0, error('Cannot write paper_tables.md (is it open in another program?)'); end
fwrite(fid, buf);  fclose(fid);
fprintf('Wrote %s and fig_*.png\n', fullfile(d,'paper_tables.md'));
end

function T = tryRead(d, name)
f = fullfile(d, name);
if ~exist(f,'file'), fprintf('skip (missing): %s\n', name); T = []; return; end
try
    T = readtable(f);
catch ME
    fprintf('skip (unreadable): %s (%s)\n', name, ME.message);  T = [];
end
end

function A = ad(A, varargin)
A = [A sprintf(varargin{:})];
end