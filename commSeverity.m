function s = commSeverity(comm)
%COMMSEVERITY Single 0..1 degradation-severity scalar D_C from a comm state.
%   comm is a struct with fields: packet_loss, delay_ms, aoi_s, snr_db.

pl_term = comm.packet_loss;
d_term = min(comm.delay_ms / 500.0, 1.0);
aoi_term = min(comm.aoi_s / 2.0, 1.0);
snr_term = min(max((20.0 - comm.snr_db) / 30.0, 0.0), 1.0);

s = min(max(0.35*pl_term + 0.25*d_term + 0.15*aoi_term + 0.25*snr_term, 0.0), 1.0);
end