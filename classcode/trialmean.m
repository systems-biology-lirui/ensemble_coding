function finaldata = trialmean(data,minnum)
    [trialnum,channel,time] =  size(data);
    m = floor(trialnum/minnum);
    n = minnum*m;
    
    midata = reshape(data(1:n,:,:),[minnum,m,channel,time]);
    finaldata = squmean(midata,2);
end