function [cluster,cluster_data] = patchcluster(num, stimIDs_new, timeseries)
    cluster = struct();
    cluster_data = struct();
    for i = num
        %% 找出target
        fieldname = sprintf('session%d',i);
        a = stimIDs_new.(fieldname);
        a1 = floor((a-1)/108)+1;
        cluster.(fieldname) = a1(1,:);
        a2 = mod(a,108);
        mat = a2(mod(1:72,4)==0,:);
        mat1 = mod(mat,18);
        uniqueColumns1 = [];
        aa = [];
        for col = 1:size(mat1, 2)
            uniqueValues = unique(mat1(:, col));
            aa(col) = length(uniqueValues);
            if length(uniqueValues) <= 1 && a(1,col)~=1405
                uniqueColumns1(end+1) = col;
            end
        end
        for trail = 1:143
            if length(unique(mat1(:,trail))) > 1 
                cluster.(fieldname)(2,trail) = -1;
            elseif length(unique(mat1(:,trail))) == 1 && a(1,trail) == 1405
                cluster.(fieldname)(2,trail) = 0;
            else 
                cluster.(fieldname)(2,trail) = unique(mat1(:,trail));
            end
        end

%         idxbl = cluster.(fieldname)(2,:)==0;
%         idxra = cluster.(fieldname)(2,:)==-1;
%         idxta = setdiff(1:143,[find(idxbl),find(idxra)]);
%         cluster_data.(fieldname).blank = timeseries.(fieldname)(idxbl,:,1:1640);
%         cluster_data.(fieldname).random = timeseries.(fieldname)(idxra,:,1:1640);
%         cluster_data.(fieldname).target = timeseries.(fieldname)(idxta,:,1:1640);
        

    end
end
