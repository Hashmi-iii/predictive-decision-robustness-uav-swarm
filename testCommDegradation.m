function testCommDegradation()
%TESTCOMMDEGRADATION  How does the model react when communication gets worse?
%   Run from the project root (the folder with run_all.m):   testCommDegradation
%
%   Part 1: R_D versus packet loss, delay, information age (AoI) and a combined degradation,
%           for a high, medium and low decision margin (2-action test case).
%   Part 2: the real 5-action set under combined degradation: which action is chosen,
%           how big the margin is, and how reliable R_D says the choice is.
%
%   Writes into outputs/:  comm_degradation_test.csv, comm_degradation_actions.csv,
%                          comm_degradation_test.png, comm_degradation_actions.png
if exist('extension','dir'), addpath('extension'); end   % commSeverity lives here
if ~exist('outputs','dir'), mkdir('outputs'); end

H = 3.0;  U = 0.5;  N = 2000;              % horizon (s), prediction uncertainty, Monte-Carlo samples
margins = [2.0 0.5 0.1];                   % high / medium / low decision margin
base  = struct('packet_loss',0.10,'delay_ms',100,'aoi_s',0.3,'snr_db',14);
mild  = struct('packet_loss',0.00,'delay_ms',50, 'aoi_s',0.1,'snr_db',25);

sw(1) = struct('name','Packet loss (%)','field','packet_loss','levels',[0 .05 .10 .20 .30 .40 .50],'scale',100,'combined',false);
sw(2) = struct('name','Delay (ms)',     'field','delay_ms',   'levels',[0 25 50 100 200 300 500],   'scale',1,  'combined',false);
sw(3) = struct('name','AoI (s)',        'field','aoi_s',      'levels',[0 .25 .5 1 2 3 5],          'scale',1,  'combined',false);
sw(4) = struct('name','Combined degradation (0 = mild, 1 = severe)','field','','levels',0:0.1:1,'scale',1,'combined',true);

rows = {};
for si = 1:numel(sw)
    for mi = 1:numel(margins)
        for li = 1:numel(sw(si).levels)
            lv = sw(si).levels(li);
            if sw(si).combined
                comm = degradeComm(mild, lv);
            else
                comm = base;  comm.(sw(si).field) = lv;
            end
            acts = makeSyntheticMarginScenario(margins(mi));
            res  = estimateDecisionRobustness(acts, comm, H, U, N, 1000*si + li);
            rows(end+1,:) = {sw(si).name, lv*sw(si).scale, margins(mi), res.r_d}; %#ok<AGROW>
        end
    end
end
T = cell2table(rows, 'VariableNames', {'sweep','level','margin','R_D'});
writetable(T, fullfile('outputs','comm_degradation_test.csv'));

figure('Color','w','Position',[100 100 1000 700]);
for si = 1:numel(sw)
    subplot(2,2,si); hold on;
    for mi = 1:numel(margins)
        m = strcmp(T.sweep, sw(si).name) & T.margin == margins(mi);
        plot(T.level(m), T.R_D(m), '-o', 'LineWidth',1.8, 'DisplayName', sprintf('margin %.1f', margins(mi)));
    end
    xlabel(sw(si).name); ylabel('R_D'); ylim([0 1.02]); grid on;
    if si == 1, legend('Location','southwest'); end
end
sgtitle('Decision robustness as communication degrades');
saveas(gcf, fullfile('outputs','comm_degradation_test.png'));

% ---- Part 2: real action set -------------------------------------------------------------
acts = defaultActionSet();
d = 0:0.1:1;  rows2 = cell(numel(d),4);
for k = 1:numel(d)
    comm = degradeComm(mild, d(k));
    [a, ~, m] = bestActionAndMargin(acts, comm);
    res = estimateDecisionRobustness(acts, comm, H, U, N, 5000 + k);
    rows2(k,:) = {d(k), a.name, m, res.r_d};
end
T2 = cell2table(rows2, 'VariableNames', {'degradation','chosen_action','margin','R_D'});
writetable(T2, fullfile('outputs','comm_degradation_actions.csv'));
disp(T2);

figure('Color','w','Position',[100 100 800 400]);
yyaxis left;  plot(T2.degradation, T2.R_D, '-o', 'LineWidth',1.8); ylabel('R_D'); ylim([0 1.02]);
yyaxis right; plot(T2.degradation, T2.margin, '-s', 'LineWidth',1.8); ylabel('decision margin');
hold on;
chg = find(~strcmp(T2.chosen_action(1:end-1), T2.chosen_action(2:end)));
for c = chg', xline(T2.degradation(c+1), 'k--'); end
xlabel('combined degradation'); grid on;
title('Real action set: R_D and margin (dashed line = chosen action changes)');
saveas(gcf, fullfile('outputs','comm_degradation_actions.png'));
fprintf('Saved comm_degradation_* in outputs/\n');
end
