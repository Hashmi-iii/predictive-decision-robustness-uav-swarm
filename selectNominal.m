function chosen = selectNominal(evals)
%SELECTNOMINAL Plain min J(a) baseline, ignoring robustness.

[~, m] = min([evals.cost]);
chosen = evals(m);
end