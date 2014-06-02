function [ IStackAligned ] = constructalignment( IStack, Transforms )
%CONSTRUCTALIGNMENT Transforms image stack as instructed
%   [ IStackAligned ] = constructalignment( IStack, Transforms ) Takes in
%   stack of images, IStack, and a list of Transforms. Performs alignment
%   on all images in IStack.

depth = size(IStack,3);
queue = Queue(depth);
% initially add each image to Q
for i=1:depth
  queue.push({i,IStack(:,:,i)});
end
clear IStack;
while queue.count() > 1
    queuesize = queue.count();
    for i=1:2:queuesize
        N1 = queue.pop();
        if queuesize == i
            queue.push(N1);
        else
            N2 = queue.pop();
            keys1 = N1{1};
            keys2 = N2{1};
            images1 = N1{2};
            images2 = N2{2};
            key = {[int2str(keys1(size(images1,3))),' ',int2str(keys2(1))]};
            vals = values(Transforms, key);
            vals = vals{1};
            merged = affinetransform(images1, images2, vals);
            queue.push({[keys1, keys2], merged});
            clear merged;
        end
    end
end
N = queue.pop();
IStackAligned = N{2};
    
%   % recursive implementation... too much memory overhead probably unless 
%   % split into small chunks.
%     function [ N_new ] = roughalignhelper( N )
%         
%     switch size(N, 3)
%         case 0
%         case 1
%             N_new = N;
%         otherwise
%             N1 = roughalignhelper(N(:, :, 1:floor(size(N,3)/2)));
%             N2 = roughalignhelper(N(:, :, ceil(size(N,3)/2):size(N,3)));
%             [~, N_new] = xcorr2imgs(N1(:,:,size(N1,3)), N2(:,:,1), N1, N2); 
%     end
%     
%     end

end

