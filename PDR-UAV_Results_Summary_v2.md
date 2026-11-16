# PDR-UAV: Results Summary

**Predictive Decision Robustness Under Communication Uncertainty for UAV Swarms**

## 1. Objective
To determine whether the decision robustness score R_D, the probability that a UAV swarm's chosen action
remains optimal under communication uncertainty, is a reliable predictor of decision stability, and whether
using it improves control decisions.

## 2. Scope and Method
- Simulation study; no hardware validation is included.
- Four jammer types, 30 random seeds, 2,400 decision points.
- A decision is reliable if the chosen action equals the hindsight-optimal action.
- Prediction tests use leave-one-seed-out evaluation, with 95% intervals from bootstrap resampling of seeds.

## 3. Main Results

| Question | Result |
|---|---|
| Is R_D calibrated? | Yes. Brier 0.054, ECE 0.026 (mean predicted 0.908, observed 0.885). Slight overconfidence when information is fresh. |
| Does R_D beat communication-based baselines? | Yes. AUROC 0.840 vs 0.712 and 0.707; Brier 0.054 vs 0.097 for both. |
| Is the improvement statistically reliable? | Yes. 95% intervals exclude zero: AUROC +0.07 to +0.19, Brier +0.03 to +0.06. |
| Does evaluating sampled futures help control? | Yes. Mean regret fell from about 0.032 to about 0.014 versus a single-forecast controller. |
| Does the R_D constraint add benefit? | Marginally. 4.6% lower regret than expected-cost control (15 wins, 0 losses, 385 ties in 400 runs). |
| Is the method fast enough? | Yes. 95th-percentile decision time up to 117 ms against a 1000 ms control cycle. |

## 4. Hypothesis Status

| Hypothesis | Status |
|---|---|
| H1: Communication degradation lowers R_D | Observed in simulation |
| H2: Larger decision margin raises R_D | Observed in simulation; partly built into the synthetic model |
| H3: Higher prediction uncertainty lowers R_D | Not tested separately |
| H4: Topology changes R_D | Inconclusive |
| H5: R_D predicts switching better than communication variables | Supported |
| H6: The R_D constraint reduces harmful switching | Weakly supported (small gain, no harm) |

## 5. Conclusions
1. R_D is a calibrated, decision-specific measure of reliability.
2. It predicts decision stability significantly better than regression on message age and decision margin.
3. Most of the control benefit comes from evaluating actions over sampled futures. The R_D constraint adds a small further gain.

## 6. Limitations
- R_D uses the same decision model that generates the outcomes, which favors it in the comparison.
- Baselines did not include packet loss, delay, topology or prediction uncertainty.
- GRU and GNN predictors did not outperform persistence.
- The theoretical stability bound certified none of the tested cases.
- Delay-only and age-of-information-only sweeps were not performed.
