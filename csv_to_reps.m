function reps = csv_to_reps(file, P)
%CSV_TO_REPS  Telemetry CSV -> struct array of reports `rep` that pdr_decide accepts.
%   Columns: t, then for UAV i=1..N: x_i,y_i,vx_i,vy_i,age_i ; then jamx,jamy,jampow,jamage,commewm,communc.
%   Units: metres, m/s, seconds (age in control steps), dBm.
M = dlmread(file, ',', 1, 0);
N = P.N;
need = 1 + 5*N + 6;
if size(M,2) ~= need, error('csv_to_reps: expected %d columns, got %d', need, size(M,2)); end
reps = repmat(struct('posHat',[],'velHat',[],'age',[],'jamPosHat',[],'jamPowHat',[],'jamAge',[],'commEwm',[],'commUnc',[]), size(M,1), 1);
for r = 1:size(M,1)
    B = reshape(M(r, 2:1+5*N), 5, N)';          % N x 5 : x y vx vy age
    reps(r).posHat = B(:,1:2);  reps(r).velHat = B(:,3:4);  reps(r).age = B(:,5);
    J = M(r, 2+5*N:end);
    reps(r).jamPosHat = J(1:2);  reps(r).jamPowHat = J(3);  reps(r).jamAge = J(4);
    reps(r).commEwm = J(5);  reps(r).commUnc = J(6);
end
end
