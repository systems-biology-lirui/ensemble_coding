function [ori_data] = patchcluster2(cluster,num)
%这里设定为了第10列是random，11列是blank
ori_data = {};
for i = num
    fieldname = sprintf('session%d',i);
    for ori = 1:11
        for location = 1:13
            if ori <10
                idx = find(cluster.(fieldname)(1,:)==location & cluster.(fieldname)(2,:)==ori*2-1);
                ori_data{location,ori} = timeseries.(fieldname)(idx,1:96,1:1640);
            elseif ori == 10
                idx = find(cluster.(fieldname)(1,:)==location & cluster.(fieldname)(2,:)==-1);
                ori_data{location,ori} = timeseries.(fieldname)(idx,1:96,1:1640);
            elseif ori == 11
                idx = find(cluster.(fieldname)(1,:)==14 & cluster.(fieldname)(2,:)==0);
                ori_data{location,ori} = timeseries.(fieldname)(idx,1:96,1:1640);
            end
        end
    end
end