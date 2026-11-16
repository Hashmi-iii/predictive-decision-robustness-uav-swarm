function degraded = degradeComm(nominal, delta)
%DEGRADECOMM C_t^delta = D_delta(C_t): push a comm state toward worse
%   values by delta in [0,1].

delta = min(max(delta, 0.0), 1.0);

degraded.packet_loss = min(max(nominal.packet_loss + delta * (1.0 - nominal.packet_loss), 0), 1);
degraded.delay_ms = nominal.delay_ms + delta * 800.0;
degraded.aoi_s = nominal.aoi_s + delta * 3.0;
degraded.snr_db = nominal.snr_db - delta * 25.0;
end