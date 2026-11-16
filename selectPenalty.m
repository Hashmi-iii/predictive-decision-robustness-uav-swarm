function chosen = selectPenalty(evals, lambda_r)
%SELECTPENALTY a* = argmin  J(a) + lambda_R * (1 - R_D(a))

scores = [evals.cost] + lambda_r * (1 - [evals.r_d]);
[~, m] = min(scores);
chosen = evals(m);
end