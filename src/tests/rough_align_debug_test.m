% have r1, r2, rot
r1 = [2,34,17,80,32,53,17,61,27,66,69,75,46,9,23,92,16,83,54,100,8,45,11,97,1,78,82,87,9,40];
r2 = [26,81,44,92,19,27,15,14,87,58,55,15,86,63,36,52,41,8,24,13,19,24,42,5,91,95,50,49,34,91];
rot = [67,21,141,71,44,73,18,24,170,173,104,11,43,64,148,3,8,31,117,132,117,82,99,54,135,35,124,34,67,113];

n = 30;
data = zeros(512, 512, n);
for i=1:n
    im = imageAC4(r1(i):r1(i)+511, r2(i):r2(i)+511, 1);
    data(:,:,i) = imrotate(im, rot(i), 'nearest', 'crop');
end

[transforms, merged] = roughalign(data, 'align');

align_gui