%RUN_ALL  Runs the final experiment set in order (no loops on purpose: each
%   experiment script starts with `clear`, which would wipe a loop variable).
%   Needs the Statistics and Machine Learning Toolbox for exp7, exp8, exp9.
%   Total runtime: a few minutes. Figures are saved to .\outputs\

exp1_margin_sweep
exp2_packetloss_and_key_comparison
exp4_theoretical_bound
exp5_topology_sweep
exp6_horizon_sweep
exp7_model_comparison
exp8_ablation_study
exp9_generalization
exp10_dynamic_degradation
exp12_end_to_end_integration
exp12b_multi_trajectory
exp12c_transition_vs_plateau
exp13_statistical_confidence
exp13b_rmin_regret_sweep
% exp3_controller_comparison and exp11_tradeoff_analysis are exploratory
% (single seed / older R_min); exp13 + exp13b supersede them. Run manually if needed.
