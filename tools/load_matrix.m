function [timeseries, stimres, stimIDs, MUAs] = load_matrix(num, name, path)
    
    allSessions = struct();
    timeseries = struct();
    stimres = struct();
    stimIDs = struct();
    MUAs = struct();

    for i = num
        isc = i;
        m = sprintf('%02d',isc);
        filename = sprintf('DG2-u%s-0%s-500Hz.mat',num2str(name), m);
        file_path = fullfile(path,filename);
        allSessions.(sprintf('session%d', i)).Datainfo = load(file_path);
        timeseries.(sprintf('session%d', i)) = allSessions.(sprintf('session%d', i)).Datainfo.Datainfo.trial_LFP;%时间序列
        stimres.(sprintf('session%d', i)) = allSessions.(sprintf('session%d', i)).Datainfo.Datainfo.VSinfo.sMbmInfo.respCode;
        stimIDs.(sprintf('session%d', i)) = allSessions.(sprintf('session%d', i)).Datainfo.Datainfo.Seq.StimID;%呈现序列
        MUAs.(sprintf('session%d', i)) = allSessions.(sprintf('session%d', i)).Datainfo.Datainfo.trial_MUA{2};%MUA,可以用来比较blank和target

    end
end