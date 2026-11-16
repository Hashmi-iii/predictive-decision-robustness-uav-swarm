function chosen = selectConstrained(evals, r_min)
%SELECTCONSTRAINED min J(a) s.t. R_D(a) >= R_min.
%   Falls back to the most robust action if nothing clears the bar.

r_d_all = [evals.r_d];
feasibleIdx = find(r_d_all >= r_min);

if ~isempty(feasibleIdx)
    costs = [evals(feasibleIdx).cost];
    [~, m] = min(costs);
    chosen = evals(feasibleIdx(m));
else
    [~, m] = max(r_d_all);
    chosen = evals(m);
end
end