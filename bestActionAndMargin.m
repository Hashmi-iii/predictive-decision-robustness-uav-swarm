function [bestAction, bestCost, margin, sortedIdx, sortedCosts] = bestActionAndMargin(actions, comm)
%BESTACTIONANDMARGIN Sort action costs and compute M_D.
%   M_D = J(a_(2)) - J(a_(1)).

n = numel(actions);
costs = zeros(1, n);
for i = 1:n
    costs(i) = decisionCost(actions(i), comm);
end

[sortedCosts, sortedIdx] = sort(costs);
bestAction = actions(sortedIdx(1));
bestCost = sortedCosts(1);

if n > 1
    margin = sortedCosts(2) - sortedCosts(1);
else
    margin = Inf;
end
end