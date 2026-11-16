function c = connectivityCost(action, comm)
%CONNECTIVITYCOST J_connectivity: worse comm -> higher cost, scaled by
%   how sensitive this action is to connectivity.

sev = commSeverity(comm);
c = action.connectivity_sensitivity * (3.0 * sev);
end