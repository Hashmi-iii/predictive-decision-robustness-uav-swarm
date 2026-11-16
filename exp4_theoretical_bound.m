%EXP4_THEORY_VS_EMPIRICAL_CONSISTENCY
%   WORDING: this is a CONSISTENCY check, not an independent theoretical
%   validation -- the closed-form curve uses the SAME noise sigma that
%   generates the Monte Carlo samples. It shows the Monte Carlo code is
%   implemented correctly; it does not independently prove the theory.
%
%   Tests the theoretical decision-persistence condition M_D > 2*L_J*L_C*D_C
%   against the empirical Monte Carlo R_D.
%
%   In this codebase, observationNoiseSigma(comm, uncertainty) IS the
%   L_J*||delta_I|| term -- it already folds in comm severity D_C and
%   prediction uncertainty U_C. Since the noise is Gaussian, we can derive
%   an EXACT closed-form R_D(M_D) and compare it directly to the Monte
%   Carlo estimate (stronger check than just one threshold number):
%
%   cost_diff = M_D + (eps2 - eps1), eps1,eps2 ~ N(0,sigma^2) independent
%   => cost_diff ~ N(M_D, 2*sigma^2)
%   => R_D_theory(M_D) = P(cost_diff > 0) = 0.5*(1 + erf(M_D/(2*sigma)))

clear; clc;

margins = [0.05, 0.1, 0.25, 0.5, 1.0, 2.0, 3.0];
nominalComm = struct('packet_loss', 0.20, 'delay_ms', 120, 'aoi_s', 0.4, 'snr_db', 12);
horizon_s = 3.0;
uncertainty = 0.6;
n_samples = 2000;
seeds = 0:4;

sigma = observationNoiseSigma(nominalComm, uncertainty);
M_D_star = 2 * sigma;   % deterministic worst-case persistence threshold

fprintf('Effective noise scale sigma = %.4f\n', sigma);
fprintf('Theoretical worst-case persistence threshold: M_D > %.4f\n\n', M_D_star);

mean_rd_empirical = zeros(size(margins));
rd_theory = zeros(size(margins));

for mi = 1:numel(margins)
    m = margins(mi);
    actions = makeSyntheticMarginScenario(m);

    trial_rd = zeros(size(seeds));
    for si = 1:numel(seeds)
        seed = seeds(si) * 97 + round(m * 1000);
        res = estimateDecisionRobustness(actions, nominalComm, horizon_s, uncertainty, n_samples, seed);
        trial_rd(si) = res.r_d;
    end
    mean_rd_empirical(mi) = mean(trial_rd);

    rd_theory(mi) = 0.5 * (1 + erf(m / (2 * sigma)));

    if m > M_D_star
        label = 'theory: persistence predicted';
    else
        label = 'theory: switching possible';
    end
    fprintf('M_D=%5.2f  R_D_empirical=%.3f  R_D_theory=%.3f  (%s)\n', ...
        m, mean_rd_empirical(mi), rd_theory(mi), label);
end

figure('Color', 'w');
plot(margins, mean_rd_empirical, '-o', 'Color', [0.06 0.43 0.34], 'LineWidth', 2, ...
    'DisplayName', 'Empirical (Monte Carlo)');
hold on;
plot(margins, rd_theory, '--s', 'Color', [0.85 0.35 0.19], 'LineWidth', 2, ...
    'DisplayName', 'Theoretical (closed-form)');
xline(M_D_star, ':k', '2\sigma threshold', 'LineWidth', 1.5, 'HandleVisibility', 'off');
hold off;
xlabel('Decision margin  M_D');
ylabel('Decision robustness  R_D');
title('Theory-vs-empirical consistency check (same noise model)');
ylim([0 1.02]);
legend('Location', 'best');
grid on;

outDir = fullfile(pwd, 'outputs');
if ~exist(outDir, 'dir')
    [ok, msg] = mkdir(outDir);
    if ~ok
        warning('Could not create outputs folder (%s). Saving to current folder instead.', msg);
        outDir = pwd;
    end
end
saveas(gcf, fullfile(outDir, 'exp4_theory_vs_empirical.png'));
fprintf('\nSaved plot to %s\n', fullfile(outDir, 'exp4_theory_vs_empirical.png'));