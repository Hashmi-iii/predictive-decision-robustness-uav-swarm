function sigma = observationNoiseSigma(comm, uncertainty)
%OBSERVATIONNOISESIGMA Std-dev of per-action information noise on J(a).
%   Represents noisy information state I_t: independent per-action
%   estimation error that grows with comm severity and prediction
%   uncertainty U_C. This is what lets low-margin decisions flip while
%   high-margin ones stay put.

sev = commSeverity(comm);
sigma = 0.05 + 2.2 * (sev ^ 1.3) * (0.3 + uncertainty);
end