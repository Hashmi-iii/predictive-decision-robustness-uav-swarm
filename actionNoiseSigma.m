function sigma = actionNoiseSigma(action, comm, uncertainty)
%ACTIONNOISESIGMA Per-action noise std-dev: combines the shared,
%   comm-driven noise (observationNoiseSigma) with THIS ACTION's own
%   connectivity_sensitivity, so less-connectivity-sensitive actions also
%   have more STABLE cost estimates under uncertainty, not just lower
%   mean connectivity cost. Without this, "most robust action" and
%   "lowest cost action" are mathematically guaranteed to be identical
%   (confirmed by the exp12 diagnostic) -- this breaks that coupling.
%
%   Calibrated so connectivity_sensitivity=1.0 gives factor=1.0 exactly,
%   matching the OLD shared-sigma behavior -- this means every prior
%   result using makeSyntheticMarginScenario (exp1/2/4/5/6/13-A, which
%   always use sensitivity=1.0 for both actions) is UNCHANGED. Only
%   results using defaultActionSet (exp3/7/8/9/11/12/12b/13-B, which vary
%   sensitivity 0.2-1.0) are affected -- those need to be rerun.

baseSigma = observationNoiseSigma(comm, uncertainty);
factor = 0.5 + 0.5 * action.connectivity_sensitivity;
sigma = baseSigma * factor;
end