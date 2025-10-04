function StimID = real_stimID(Datainfo, day)
    % 矫正StimID以匹配实际数据
    %
    % 输入参数:
    %   Datainfo - 数据结构体，包含StimID和响应码等信息
    %   day      - 当前实验天
    %
    % 输出参数:
    %   StimID   - 矫正后的StimID

    % 每个Trial的图片数
    trail_picnum = 72 * (day < 24) + 52 * (day >= 24);

    % 计算TrialStimID矩阵
    allpicnum = length(Datainfo.Seq.StimID);
    TrialStimID = reshape(Datainfo.Seq.StimID, [trail_picnum, allpicnum / trail_picnum])';

    % 矫正StimID
    RealOrdid = [];
    for kk = 1:length(Datainfo.VSinfo.sMbmInfo.respCode)
        RealOrdid = [RealOrdid; TrialStimID(kk, :)];
        if Datainfo.VSinfo.sMbmInfo.respCode(kk) ~= 1
            TrialStimID = cat(1, TrialStimID, TrialStimID(kk, :));
        end
    end

    % 提取有效Trial
    RealTrialID = find(Datainfo.VSinfo.sMbmInfo.respCode == 1);
    StimID = RealOrdid(RealTrialID, :)';
end