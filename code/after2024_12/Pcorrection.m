function correlationMatrix = Pcorrection(All_data_pre1,All_data_pre2,condition)

minnum1 = inf;
minnum2 = inf;


% 找到最小数据量
for ori = 1:18
    minnum1 = min(minnum1, size(All_data_pre1{condition(1), ori}, 1));
    minnum2 = min(minnum2, size(All_data_pre2{condition(2), ori}, 1));
end

minnum = min([minnum1,minnum2]);
minnum = floor(minnum / 20) * 20;

data1 = zeros(18,minnum,coilnum,length(window));
data2 = zeros(18,minnum,coilnum,length(window));

load('/home/dclab2/Ensemble coding/data/SNR.mat','coilSNR');
[~,coilidx] = sort(coilSNR,'descend');
coilselect = coilidx(1:coilnum);
% 数据量匹配
for ori = 1:18
    a = size(All_data_pre1{condition(1),ori},1);
    selected_numbers = randperm(a, minnum);
    for i = 1:length(selected_numbers)
        for coil = 1:length(coilselect)
            data1(ori,i,coil,:) = squeeze(All_data_pre1{condition(1),ori}(selected_numbers(i),coilselect(coil),:));
            data2(ori,i,coil,:) = squeeze(All_data_pre2{condition(2),ori}(selected_numbers(i),coilselect(coil),:));
        end
    end
end

data10 = zeros(18*minnum/20,coilnum,size(All_data_pre1{condition,ori},3));
data20 = zeros(18*minnum/20,coilnum,size(All_data_pre2{condition,ori},3));

for ori = 1:18
    b = minnum/20;
    for meannum = 1:b
        data = squeeze(mean(data1(ori,(b-1)*20+(1:20),:,:),2));       
        data10((ori-1)*b+meannum,:,:) = data;
        data = squeeze(mean(data2(ori,(b-1)*20+(1:20),:,:),2)); 
        data20((ori-1)*b+meannum,:,:) = data;
    end
end

dataset = cat(1,data10,data20);
numMatrices = size(dataset,1);

correlationMatrix = zeros(numMatrices,numMatrices);

for i = 1:numMatrices
    for j = i:numMatrices % 只计算上三角部分，提高效率
        
        % 将矩阵展开为向量
        vector1 = reshape(squeeze(dataset(i,:,:)), [], 1); % 将第 i 个矩阵拉平成向量
        vector2 = reshape(squeeze(dataset(j,:,:)), [], 1); % 将第 j 个矩阵拉平成向量
        
        % 计算相关性
        correlationMatrix(i, j) = corr(vector1, vector2); % 皮尔逊相关性
        correlationMatrix(j, i) = correlationMatrix(i, j); % 对称性
    end
    %disp(i);
end
figure;
imagesc(correlationMatrix); % 显示相关性矩阵
colorbar;
        
        
        