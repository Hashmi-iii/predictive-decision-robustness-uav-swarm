function samples = sampleFutureComm(nominal, horizon_s, uncertainty, n_samples)
%SAMPLEFUTURECOMM Draw N samples from p(C_{t+tau} | I_t).
%   Persistence-plus-Gaussian-noise predictor. Spread widens with both
%   uncertainty (U_C) and horizon_s (tau).

spread = uncertainty * (1.0 + 0.15 * horizon_s);

for i = 1:n_samples
    pl = min(max(nominal.packet_loss + 0.10 * spread * randn(), 0), 1);
    d = max(0.0, nominal.delay_ms + 120.0 * spread * randn());
    aoi = max(0.0, nominal.aoi_s + 0.6 * spread * randn());
    snr = nominal.snr_db + 6.0 * spread * randn();

    samples(i).packet_loss = pl;
    samples(i).delay_ms = d;
    samples(i).aoi_s = aoi;
    samples(i).snr_db = snr;
end
end