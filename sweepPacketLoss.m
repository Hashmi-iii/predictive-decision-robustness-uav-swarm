function rd_values = sweepPacketLoss(pl_levels, margin, uncertainty, horizon_s, n_samples, label)
%SWEEPPACKETLOSS R_D across packet-loss levels at a fixed decision margin.

rd_values = zeros(size(pl_levels));

for i = 1:numel(pl_levels)
    pl = pl_levels(i);
    comm = struct('packet_loss', pl, 'delay_ms', 100, 'aoi_s', 0.3, 'snr_db', 14);
    actions = makeSyntheticMarginScenario(margin);
    seed = round(pl * 1000) + 1;
    res = estimateDecisionRobustness(actions, comm, horizon_s, uncertainty, n_samples, seed);
    rd_values(i) = res.r_d;
end

fprintf('[%s] margin=%.2f, U_C=%.2f: ', label, margin, uncertainty);
for i = 1:numel(pl_levels)
    fprintf('PL=%.0f%%->R_D=%.2f  ', pl_levels(i) * 100, rd_values(i));
end
fprintf('\n');
end