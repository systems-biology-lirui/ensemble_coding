%构建模型,先选用739——008做
%这一步得出的是每一个刺激开始的帧数，总长是1640。
currSync = [];
for i =1:66
    currSync(:,i) = ceil((double(Datainfo.Sync(6:77,i)) - double(Datainfo.Sync(1,i)))/Datainfo.SampleRT*Datainfo.AnalysisRT);
end



%对应到每个帧上
sti_matrix = [];
for i = 1:66
    m=1;
    for j = 1:1640
        if m <73
            if j < currSync(1,i)
                sti_matrix(j,i) = 0;
            elseif j == currSync(m,i)
                sti_matrix(j:j+19,i) = m;
                m =m+1;
                if j == currSync(end,i)
                    sti_matrix(j+20:1640,i) = 0;
                end
            end
        end
    end
end


%先对应到实际的gsq上，即知道是哪个图片
sequence =reshape(sequence_EC_new,[72,66]);
flash = [];
a =sti_matrix;
for i =1:66
    for j = 1:72
        a(find(sti_matrix(:,i)==j),i) = sequence(j,i);
    end
end

%导入刺激的图片信息,这里需要包括单个的朝向的信息，单个乘积的信息，全乘积的信息。
%为了方便以后计算，我先把EC的图片的小光栅数据与原始图片的数据做对应

fakesaber = saber;
%但是目前对于朝向究竟该怎么表示还不确定，采用高斯函数？让两侧接近0，90为最高点，还是-1到1.
for i = 1:379
    fakesaber(3:6,i) = data(1,9:12,saber(2,i))';
    fakesaber(7:14,i) = data(1,1:8,saber(2,i))';
    fakesaber(15,i) = data(3,1,saber(2,i));
    for in = 1:3
        fakesaber(in+15,i) = fakesaber(in+2,i)*fakesaber(in+3,i);
    end
    fakesaber(19,i) = fakesaber(3,i)*fakesaber(6,i);
    for out = 1:7
        fakesaber(out+19,i) = fakesaber(out+6,i)*fakesaber(out+7,i);
    end
    fakesaber(27,i) = fakesaber(7,i)*fakesaber(14,i);
    fakesaber(28,i) = log(prod(fakesaber(3:14,i)));
end
save('ECstidata.mat',"fakesaber")
b=a ;
sti = [];
for n = 1:12
    for i =1:66
        for j = 1:324
            b(find(a(:,i)==j),i) = fakesaber(n+2,j);
    
        end
    end
    sti(:,n) = reshape(b,[1640*66,1]);
end
save("u739008ECsti.mat","sti");
res = permute(Datainfo.trial_LFP,[3,1,2]);
res1 = reshape(res(1:1640,:,:),[66*1640,100]);
res = res1(:,1:96);
