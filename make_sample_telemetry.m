%MAKE_SAMPLE_TELEMETRY  Writes outputs_addon/sample_telemetry.csv in the exact column format that
%   hil/csv_to_reps.m expects, generated from the simulator. Real flight logs must be converted to
%   this same format (see HIL_PLAN.md); this file proves the round trip works before hardware exists.
clear; clc;  addon_paths();
P = swarmParams();  T = 30;  seed = 5;  rng(seed);
shadow = P.shadowSigma * randn(P.N);
[jpT, jwT] = genJammerScenario('creeping', T, P, seed);
X.pos = P.O;  X.vel = zeros(P.N,2);  X.c = [0 0];
I = initInfoState(X, jpT(1,:), jwT(1), P);
if ~exist('outputs_addon','dir'), mkdir('outputs_addon'); end
fid = fopen('outputs_addon/sample_telemetry.csv','w');
h = 't';
for i = 1:P.N, h = [h sprintf(',x%d,y%d,vx%d,vy%d,age%d', i,i,i,i,i)]; end %#ok<AGROW>
fprintf(fid, '%s,jamx,jamy,jampow,jamage,commewm,communc\n', h);
for t = 1:T
    row = sprintf('%d', t);
    for i = 1:P.N
        row = [row sprintf(',%.4f,%.4f,%.4f,%.4f,%d', I.posHat(i,1), I.posHat(i,2), I.velHat(i,1), I.velHat(i,2), I.age(i))]; %#ok<AGROW>
    end
    fprintf(fid, '%s,%.4f,%.4f,%.4f,%d,%.5f,%.5f\n', row, I.jamPosHat(1), I.jamPosHat(2), I.jamPowHat, I.jamAge, I.commEwm, I.commUnc);
    out = pdr_decide(I, P, 20, 1, shadow);
    ap = resolveAction(out.action, X.c, I.jamPosHat, P);
    W = P.wnoise * randn(P.N, 2, 1, P.nsub);
    for m = 1:P.nsub, [X, ~] = swarmSubstep(X, ap, P, W(:,:,:,m)); end
    [plr, snr] = linkModel(X.pos, jpT(t,:), jwT(t), P, shadow);
    I = updateInfoState(I, X, plr(:,1), commFromLinks(plr, snr, P), jpT(t,:), jwT(t), P);
end
fclose(fid);
fprintf('Saved outputs_addon/sample_telemetry.csv (%d rows)\n', T);
