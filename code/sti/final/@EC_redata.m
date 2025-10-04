% ------------------------用于找回EC中小光栅的数据-----------------------------%
clear;
session = struct();
for i = 1:379
    idx = sprintf('%03d',i);
    filename = sprintf('0000000%s.bmp',idx);
    filepath = fullfile('D:\Desktop\Ensemble coding\sti\0801\z432s2_EC_20240801',filename);
    session.new.(sprintf('pic%d',i)) = imread(filepath);
end
for i = 1:144
    idx1 = sprintf('%03d',i);
    idx3 = sprintf('%03d',i);
    idx5 = sprintf('%03d',i);
    filename1 = sprintf('0000000%s.bmp',idx1);
    filename3 = sprintf('0000000%s.bmp',idx3);
    filename5 = sprintf('0000000%s.bmp',idx5);
    filepath1 = fullfile('D:\Desktop\data\0730\1\1',filename1);
    filepath3 = fullfile('D:\Desktop\data\0730\3\1',filename3);
    filepath5 = fullfile('D:\Desktop\data\0730\5\1',filename5);
    session.old1.(sprintf('pic%d',i)) = imread(filepath1);
    session.old3.(sprintf('pic%d',i)) = imread(filepath3);
    session.old5.(sprintf('pic%d',i)) = imread(filepath5);
end
saber =[];
num = 0;
for i = 1:379
    for m = 1:2:5
        for n = 1:144
            a = isequal(session.new.(sprintf('pic%d',i)),session.(sprintf('old%d',m)).(sprintf('pic%d',n)));
            if a == 1
                num = num+1;
                saber(1,i) = m;
                saber(2,i) = n;
            end
        end
    end
end


% 发现原来当时是做了复制，实际上只用了10度的数据库。
% EC_data = [];
% data = load('D:\Desktop\data\0730\1\data10.mat');
% for i = 1:379
%     EC_data(:,:,i) = data(:,:,saber(2,i));
% end





% ---------------------重新构建刺激库（原批量改名）---------------------------------------%
colormap = imfinfo('D:\Desktop\data\0730\1\1\0000000001.bmp').Colormap;
idx = [1:6:36,37:138];
new = uint8(zeros(241, 241, 108, 3));%
for mm = 1:3
    idx =[1,3,5];
    repeat = idx(mm);
    for i = 1:108
        a = session.(sprintf('old%d',repeat)).(sprintf('pic%d',i));
        new(:,:,i,mm) = a;
    end
    if repeat == 3
        new1 = new(:,:,:,mm);
        new1(:,:,1:12) = new(:,:,7:18,mm);
        new1(:,:,13:18) = new(:,:,1:6,mm);
        new(:,:,:,mm) = new1;  
    elseif repeat == 5
        new1 = new(:,:,:,mm);
        new1(:,:,1:24) = new(:,:,7:30,mm);
        new1(:,:,25:30) = new(:,:,1:6,mm);
        new(:,:,:,mm) = new1;
    end
end
% new_random = uint8([]);
% for i = 1:108
%     new_random(:,:,i) = new(:,:,randi(108),randi(3));
% end
all = uint8([]);
for i = 1:324/18
    all(:,:,(i-1)*18+1:(i-1)*18+6) = new(:,:,(i-1)*6+1:i*6,1);
    all(:,:,(i-1)*18+7:(i-1)*18+12) = new(:,:,(i-1)*6+1:i*6,2);
    all(:,:,(i-1)*18+13:(i-1)*18+18) = new(:,:,(i-1)*6+1:i*6,3);
end
% all = cat(3,all,new_random);


%------------------------------------检测---------------------------------------%
saber1 = [];
num1 =0;
for i = 1:324
    for m = 1:2:5
        for n = 1:144
            a = isequal(all(:,:,i),session.(sprintf('old%d',m)).(sprintf('pic%d',n)));
            if a == 1
                num1 = num1+1;
                saber1(1,i) = m;
                saber1(2,i) = n;
            end
        end
    end
end

for i = 1:324
    id = sprintf('%03d',i);
    filename = sprintf('0000000%s.bmp',id);
    filepath = fullfile('D:\Desktop\new\ec',filename);
    imwrite(all(:,:,i),colormap,filepath);
end
