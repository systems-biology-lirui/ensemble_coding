function[stimIDs_new] = real_sequence(num, stimres, stimIDs)
    stimIDs_new = struct();
    for i = num
        fieldnn = sprintf('session%d',i);
        trailnum = length(stimIDs.(fieldnn));
        TrialStimID=reshape(stimIDs.(sprintf('session%d',i)),[72 trailnum/72])';
        RealOrdid = [];
        RealOrdbuffid = TrialStimID;
        RealOrdbufferrorid = [];
        for kk = 1:length(stimres.(sprintf('session%d',i)))
            RealOrdid = [RealOrdid;RealOrdbuffid(kk,:)];
            if stimres.(sprintf('session%d',i))(kk)==1
            else
                RealOrdbuffid = cat(1,RealOrdbuffid,RealOrdbuffid(kk,:));
            end
        end
        RealTrialID=find(stimres.(sprintf('session%d',i))==1);
        StimID=RealOrdid(RealTrialID,:);
    
        StimID = StimID';
        stimIDs_new.(sprintf('session%d',i)) = StimID;
    end
end