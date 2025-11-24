function SSGv = getSSGvPattern(MGv,SSGv)
    for i = 1:height(SSGv.FinalData.Meta)
        condition = SSGv.FinalData.Meta.Condition(i);
        idx = find(MGv.FinalData.Meta.Condition == condition,1,'first');
        SSGv.FinalData.Pattern(i) = MGv.FinalData.Pattern(idx);
    end