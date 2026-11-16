%EXP2_PACKETLOSS_AND_KEY_COMPARISON

clear; clc;

pl_levels = [0.0, 0.05, 0.10, 0.20, 0.30, 0.40, 0.50];
horizon_s = 3.0;
n_samples = 2000;

rd_high = sweepPacketLoss(pl_levels, 2.0, 0.5, horizon_s, n_samples, 'high margin');
rd_low  = sweepPacketLoss(pl_levels, 0.1, 0.5, horizon_s, n_samples, 'low margin');

pl = 0.20;
comm = struct('packet_loss', pl, 'delay_ms', 100, 'aoi_s', 0.3, 'snr_db', 14);

stateA = makeSyntheticMarginScenario(2.5);
resA = estimateDecisionRobustness(stateA, comm, horizon_s, 0.25, 4000, 1);

stateB = makeSyntheticMarginScenario(0.08);
resB = estimateDecisionRobustness(stateB, comm, horizon_s, 0.90, 4000, 2);

fprintf('\n=== Key comparison: identical PL, different R_D ===\n');
fprintf('State A: PL=%.0f%%, M_D=%.2f, U_C=0.25 -> R_D=%.3f\n', pl * 100, resA.margin, resA.r_d);
fprintf('State B: PL=%.0f%%, M_D=%.2f, U_C=0.90 -> R_D=%.3f\n', pl * 100, resB.margin, resB.r_d);
fprintf('=> Communication quality alone does NOT predict decision reliability.\n\n');

figure('Color', 'w');
plot(pl_levels * 100, rd_high, '-o', 'Color', [0.06 0.43 0.34], 'LineWidth', 2, ...
    'DisplayName', 'High margin (M_D=2.0)');
hold on;
plot(pl_levels * 100, rd_low, '-s', 'Color', [0.85 0.35 0.19], 'LineWidth', 2, ...
    'DisplayName', 'Low margin (M_D=0.1)');
hold off;
xlabel('Packet loss (%)');
ylabel('Decision robustness  R_D');
title('R_D vs packet loss, at two fixed decision margins');
ylim([0 1.02]);
legend('Location', 'best');
grid on;

if ~exist('outputs', 'dir')
    mkdir('outputs');
end
saveas(gcf, fullfile('outputs', 'exp2_packetloss_sweep.png'));
fprintf('Saved plot to outputs/exp2_packetloss_sweep.png\n');