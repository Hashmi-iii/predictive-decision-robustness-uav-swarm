function j = decisionCost(action, comm, w_m, w_c, w_e, w_f)
%DECISIONCOST J(a) = w_m*J_mission + w_c*J_connectivity + w_e*J_energy + w_f*J_formation

if nargin < 3 || isempty(w_m), w_m = 1.0; end
if nargin < 4 || isempty(w_c), w_c = 1.0; end
if nargin < 5 || isempty(w_e), w_e = 0.5; end
if nargin < 6 || isempty(w_f), w_f = 0.5; end

j = w_m * action.mission_cost ...
  + w_c * connectivityCost(action, comm) ...
  + w_e * action.energy_cost ...
  + w_f * action.formation_cost;
end