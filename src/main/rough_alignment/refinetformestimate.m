function [ besttform, besterror, bestmerged ] = refinetformestimate( config, T, A, tform )
%REFINETFORMESTIMATE Improve alignment by iterating over a small range of
%possible rotation angles
%   [ besttform, besterror, bestmerged ] = refinetformestimate( config, T, A, tform )
%   T and A are two matrices, unaligned, and tfrom is the transformation
%   matrix that aligns T with A. The reason for this refinement is because
%   the rotation angle is discretized. By refining, a theta value within
%   the original discrete theta units may be found that minimizes error
%   function. config is the alignment config variables set by setalignvars.

% initialize best transform results with input values
bestmerged = affinetransform(T, A, tform);
besterror = errormetrics(config, bestmerged, intmax);
besttform = tform;
if besterror == intmax  % if greater than minnonzeropercent, terminate
    return;
end
besttparam = matrix2params(tform);
invariantparam = besttparam;
bounds = 360/min(min(size(A), size(T)));

% iterate over all possible theta values in a narrow range
for theta = linspace(-bounds, bounds, 6);
    tempparam = invariantparam + [0, 0, theta];
    tempaligned = affinetransform(T, A, params2matrix(tempparam));
    temperror = errormetrics(config, tempaligned, intmax);
    if temperror < besterror    % update best transform results
        besttform = params2matrix(tempparam);
        besterror = temperror;
        bestmerged = tempaligned;
    end
end

end
