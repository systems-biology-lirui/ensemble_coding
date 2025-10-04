function [ori_tuning] = oriECSC_tuningold(num,type,stimIDs_new,timeseries)

fakesaber_1(13,:) = mean(fakesaber_1(1:12,:),1);
ori_tuning = {};
for i = num
    fieldnn = sprintf('session%d',i);
    for ori = 1:18
        if type == 0       
            for trail = 1:length(stimIDs_new.(fieldnn)(1,:))
                for flash = 16:64
                    winstart = flash*20+100-50;
                    winend = flash*20+100+100;
                    gsq = stimIDs_new.(fieldnn)(trail,flash);
                    if gsq < 325
                        if fakesaber_1(13,gsq) ==ori*10                      
                            data = timeseries.(fieldnn)(trail,winstart:winend);
                            if isempty(ori_tuning{ori})
                                ori_tuning{ori} = data;
                            else
                                ori_tuning{ori} = cat(1,ori_tuning{ori},data);
                            end
                        end
                    end
                end
            end
        
        elseif type ==1
            for trail = 1:length(stimIDs_new.(fieldnn)(1,:))
                for flash = 16:64
                    winstart = flash*20+100-50;
                    winend = flash*20+100+100;
                    gsq = stimIDs_new.(fieldnn)(trail,flash);
                    if gsq < 109
                        gsq1 = mod(gsq,18);
                        if gsq1 == ori
                            data = timeseries.(fieldnn)(trail,winstart:winend);
                            if isempty(ori_tuning{ori})
                                ori_tuning{ori} = data;
                            else
                                ori_tuning{ori} = cat(1,ori_tuning{ori},data);
                            end
                        end
                    end
                end
            end


        end
    end
end



            

