function [ globaltforms ] = local2globalmap(    localtforms, ...
                                                resolution, ...
                                                xoffset, ...
                                                yoffset, ...
                                                zoffset, ...
                                                xsubsize, ...
                                                ysubsize ...
                                            )
%GLOBAL2LOCALMAP Convert entire map from global to local key.
%   function [ globaltforms ] = local2globalmap(    localtforms, ...
%                                                   resolution, ...
%                                                   xoffset, ...
%                                                   yoffset, ...
%                                                   zoffset, ...
%                                                   xsubsize, ...
%                                                   ysubsize ...
%                                               )
%   localtforms is the Map with local indices as keys. globaltforms is a
%   Map with global indices for keys. All map a key to a transformation
%   matrix which determines pairwise alignment for uniquely specified
%   images.

% encode parameters into struct
index = struct;
index.resolution = resolution;
index.xoffset = xoffset;
index.yoffset = yoffset;
index.zoffset = zoffset;
index.xsubsize = xsubsize;
index.ysubsize = ysubsize;

% iterate over each map entry, convert from local to global keys
globaltforms = containers.Map;
k = keys(localtforms);
for i=1:length(k)
    localkey = k{i};
    localval = values(localtforms, k(i));
    [ index.zslice1, index.zslice2 ] = localkey2indices(localkey);
    index.zslice1 = index.zslice1 + index.zoffset;
    index.zslice2 = index.zslice2 + index.zoffset;
    globaltforms(globalindices2key(index)) = localval{1};
end

end
