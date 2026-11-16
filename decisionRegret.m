function e_d = decisionRegret(actions, true_comm, selected_action)
%DECISIONREGRET E_D = J(a_selected | I_true) - J(a_oracle | I_true)

[~, oracleCost] = bestActionAndMargin(actions, true_comm);
selectedCost = decisionCost(selected_action, true_comm);
e_d = selectedCost - oracleCost;
end