clear;


sequence_SC = [];
sequence_EC = [];
target_sequence = [];
% 序列66*72，包括9个target每个target6个，random6，blank6。每个target下面非target
% 的平均角度一致，都设置为95°。在ec中，我会设置1：324为target库，325：432为random库，
% 1张空白，其中target的排布是按照每个角度18张；SC中1：108为target，109-216为random，
% 217为一张空白，target中的排序是采用了每18张是18个角度。
sessions = 1;
trails = 66;
flashs = 72;
target = 4; %每第四张变为target
target_ori = [1,1,1,1,1,1,1,1,1,19,21];
nontarget_ori =1:18;
trail_sequence = [];
%% 如果到时候需要修改repeat，只需要改trails，和repmat的数量。

for session = 1:sessions
    matrix = repmat(target_ori,1,6);
    sequence = matrix(randperm(length(matrix))); %66的序列
    trail_sequence(session,:) = sequence;
    for trail = 1:trails
        if sequence(trail) <= 17 
            nontarget_ori_new =  nontarget_ori;
            nontarget_ori_new((sequence(trail)))=[];
            nonmartix = repmat(nontarget_ori_new,1,3);
            nonmartix2 = nonmartix(randperm(length(nonmartix)));
            nonmartix1 = [nonmartix2,nontarget_ori_new(randi(16)),nontarget_ori_new(randi(16)),nontarget_ori_new(randi(16))];
            i = 1;
            for flash = 1:flashs
                if mod(flash,4) == 0
                    target_idx = sequence(trail);
                    sequence_EC(trail,flash) = randi([(target_idx-1)*18+1,(target_idx)*18]);
                    numbers = sequence(trail):18:108;
                    sequence_SC(trail,flash) = numbers(randi(length(numbers)));
                else
                    non_idx = nonmartix1(i);
                    sequence_EC(trail,flash) = randi([(non_idx-1)*18+1,non_idx*18]);
                    nonnumbers = nonmartix1(i):18:108;
                    sequence_SC(trail,flash) = nonnumbers(randi(length(nonnumbers)));
                    i = i+1;
                end
            end
        elseif sequence(trail) == 19
            for flash = 1:flashs
                sequence_EC(trail,flash) = randi([1,324]);
                sequence_SC(trail,flash) = randi([1,108]);
            end
        elseif sequence(trail) == 21
            for flash = 1:flashs
                sequence_EC(trail,flash) = 325;
                sequence_SC(trail,flash) = 109;
            end
        end
    end
    sequence_EC_new = reshape(sequence_EC',[],1)';
    sequence_SC_new = reshape(sequence_SC',[],1)';
    filename_ec = sprintf('session%d_EC.mat',session);
    if session<=13
        filename_sc = sprintf('session%d_patch.mat',session);
    else
        filename_sc = sprintf('session%d_SC.mat',session);
    end
    %save(filename_ec,'sequence_EC_new');
    %save(filename_sc,'sequence_SC_new');
end



