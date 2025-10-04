function [cluster,clusterdata_patch] = newECpatchcluster(idx1,idx2,num,timeseries)
%给出trail label(patch)        
    cluster = {};
    for i = num
        fieldnn = sprintf('session%d',i);
        m = stimIDs_new.(fieldnn)(1,:);
        for mm = 1:length(m)
            if m(mm) <3889
                %patch(1-12location)
                n1 =floor((m(mm)-1)/12)+1;
                n2 =find(idx1==n1);
                n3= mod(m(mm),12);
                if n3 ==0
                    n3= 12;
                end
                cluster{i}(mm,1) = n2;
                cluster{i}(mm,2) = n3;
            elseif m(mm) == 3889
                cluster{i}(mm,1) = 4;
                cluster{i}(mm,2) = 0;
                %blank
            elseif m(mm) >3889 && m(mm) <3998
                %patch13
                n0 = m(mm)-3889;
                n1 = n0-floor(n0/18)*18;
                n2 = find(idx2 == n1);
                cluster{i}(mm,1) = n2;
                cluster{i}(mm,2) = 13;
            else
                %SC
                n0 = m(mm)-3997;
                n1 = n0-floor(n0/18)*18;
                n2 = find(idx2 == n1);
                cluster{i}(mm,1) = n2;
                cluster{i}(mm,2) = 14;
            end
        end
    end
    %数据分组
    clusterdata_patch = cell(3,14);
    for i = num
        fieldnn = sprintf('session%d',i);
        for c = 1:3
            for p = 1:14
                idx = find(cluster{i}(:,1)==c&cluster{i}(:,2)==p);
                data1 = timeseries.(fieldnn)(idx,1:96,420:1460)-mean(timeseries.(fieldnn)(idx,1:96,1:100),3);
                data = normalize(data1,3,"range",[0,1]);
                if isempty(clusterdata_patch{c,p})
                    clusterdata_patch{c,p} = data;
                else
                    clusterdata_patch{c,p} = cat(1,clusterdata_patch{c,p},data);

                end
            end
        end
    end
end