function [ matrix ] = params2matrix( params )
%PARAMS2MATRIX Converts transformation parameters to matrix form
%   Takes 1x3 vector of parameters and converts into 3x3 matrix. Note that
%   translation is performed first BEFORE rotation. Theta is performed in
%   the counterclockwise direction.

TY = params(1);
TX = params(2);
TH = params(3);

% obtain translation and rotation matrices
trans = [ ...
            1,  0,  0;  ...
            0,  1,  0;  ...
            TX, TY, 1   ...
        ];
rot =   [ ...
            cosd(TH),	sind(TH),	0;  ...
            -sind(TH),	cosd(TH),	0;  ...
            0,          0,          1   ...
        ];

% output final matrix
matrix = trans*rot;
end
