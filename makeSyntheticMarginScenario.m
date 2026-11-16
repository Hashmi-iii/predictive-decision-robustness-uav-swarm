function actions = makeSyntheticMarginScenario(margin, base_cost)
%MAKESYNTHETICMARGINSCENARIO 2-action toy scenario with an exact M_D.

if nargin < 2
    base_cost = 5.0;
end

actions(1) = struct('name', 'a_best', ...
    'mission_cost', base_cost, 'energy_cost', 0.0, 'formation_cost', 0.0, ...
    'connectivity_sensitivity', 1.0);

actions(2) = struct('name', 'a_second', ...
    'mission_cost', base_cost + margin, 'energy_cost', 0.0, 'formation_cost', 0.0, ...
    'connectivity_sensitivity', 1.0);
end