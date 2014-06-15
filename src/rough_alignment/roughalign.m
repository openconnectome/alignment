function [ Transforms, M_new ] = roughalign( M, varargin )
%ROUGHALIGN Aligns a stack of images
%	[ Transforms, M_new ] = roughalign( M )
%   [ Transforms, M_new ] = roughalign( M, align )
%   [ Transforms, M_new ] = roughalign( M, align, scale )
%   if align variable is 'align', M_new returns the aligned image stack;
%   otherwise M_new is nil. scale indicates how much the image should be
%   resized during the alignment process. Primarily used for large images
%   that may take up too much memory. 0.5 < scale < 1 is an appropriate
%   range. The default scale is 1. M is the image stack.

tic

% retrieve global variable
global errormeasure;
if isempty(errormeasure)
    errormeasure = 'mse';
end

% validate inputs
if size(M, 3) < 2
    error('Size of stack must be at least 2');
end
narginchk(1,3);
switch nargin
    case 1  % only image stack
        Mtemp = M;
        align = 0;
    case 2  % image stack with align params
        Mtemp = M;
        align = strcmpi(varargin{1}, 'align');
    case 3  % image stack, align, and scale params
        Mtemp = imresize(M, varargin{2});
        align = strcmpi(varargin{1}, 'align');
end

% compute pairwise transforms
Transforms = constructtransforms(Mtemp, 'improve');

% aligns the image based on the transforms if required
M_new = [];
if align
    M_new = constructalignment(M, Transforms);
    % output error report for both original and aligned stacks.
    format long g;
    [origE, orig] = errorreport(M, 'Original', errormeasure);
    [alignedE, aligned] = errorreport(M_new, 'Aligned', errormeasure);
    disp('Error improvement:');
    disp( ['Index', 'improvement', '% improvement'] );
    disp( [(1:size(origE,1))', origE-alignedE, (origE-alignedE)./origE] );
    disp(orig);
    disp(aligned);
end

toc

end
