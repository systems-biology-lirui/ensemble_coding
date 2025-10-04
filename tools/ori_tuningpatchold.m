function [ori_tuning] = ori_tuningpatchold(num,stimIDs_new,timeseries)
for i = num 
    fieldnn = sprintf('session%d'i);
    for ori = 1:18
        for location = 1:13
            for trail = 1:length(stimIDs_new.(fieldnn)(1,:))
                for flash = 16:64
                    winstart = flash*20+100-50;
                    winend = flash*20+100+100;
                    gsq = stimIDs_new.(fieldnn)(trail,flash);

                    if gsq < 1405
                        gsq1 = floor((gsq-1)/108)+1;%location
                        gsq2 = mod((gsq-(gsq1-1)*108),18);%orientation
                        if gsq2 ==ori                      
                            data = timeseries.(fieldnn)(trail,winstart:winend);
                            if isempty(ori_tuning{ori})
                                ori_tuning{ori,location} = data;
                            else
                                ori_tuning{ori,location} = cat(1,ori_tuning{ori,location},data);
                            end
                        end
                    end
                end
            end
        end
    end
end
