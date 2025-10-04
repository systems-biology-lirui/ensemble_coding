%% ---------------------------------2025.4.3------------------------------%%
% 第二只猴

% ----------------------------------- Event-------------------------------%

% experiment2 GSQ
% 每天只能做1800trial，因此按照16个条件（13*location+EC+EC0+SC）
% 每个trial 6*18+6blank = 114trial；可以得到每个ori24个repeat，每个pattern4个repeat

% Patch条件需要将13个位置进行打乱
% 114*13 = 7*16*13



% -------------------------------- SSVEP-------------------------------------%%

% 按照一个能做1800trial
% 一共16（13location+EC+EC0+SC）*11（9ori+random+blank）=176，相当于每天每种
% 条件能做10个repeat，EC/EC0/SC一个session11*10个trial。（EC还要考虑pattern）
% Patch做5个session，每个session里面2repeat*11*13trial

clear;

datetoday = '0915';
repeat = 1;
final_sessions = cell(100,4);
pic_idx_concatenated = cell(100,4);
block_Event = {'MGv','MGnv','SG','SSGnv'};
block_SSVEP_A = {'MGv','SSGnv'};
block_SSVEP_B = {'MGv','MGnv','SG','SSGnv','SSGv'};


for session = 1:20
    Event = struct();
    SSVEP = struct();
    SSVEP_b = struct();
    % 每个session内条件的重复次数

    % Exp 2
    Event = GSQ_Event_Exp2(Event,repeat);
    Event = GSQ_Event_Exp2_SSGnv(Event,repeat);

    % Exp1A
    SSVEP = GSQ_SSVEP_Exp1A(SSVEP,10);
    % SSVEP = GSQ_SSVEP_Exp1A_SSGnv(SSVEP,2);

    % Exp1B
    SSVEP_b = GSQ_SSVEP_Exp1B(SSVEP_b,1);

    % 转换ID
    [SSVEP,Event] = GSQ_feature2picID(SSVEP,Event);
    neworder = randperm(4);
    a = ones(1,4)*13;
    a(neworder==4) = 175;
    b = ones(1,4)*14;
    b(neworder==4) = 176;

    result1 = [Event.(block_Event{neworder(1)})(:,1:a(1)),...
        Event.(block_Event{neworder(2)})(:,1:a(2)),...
        Event.(block_Event{neworder(3)})(:,1:a(3)),...
        Event.(block_Event{neworder(4)})(:,1:a(4))];
    result2 = [Event.(block_Event{neworder(1)})(:,b(1):end),...
        Event.(block_Event{neworder(2)})(:,b(2):end),...
        Event.(block_Event{neworder(3)})(:,b(3):end),...
        Event.(block_Event{neworder(4)})(:,b(4):end)];

    % 原本有4种block
    % result3 = [SSVEP.(block_SSVEP_A{neworder(1)}),SSVEP.(block_SSVEP_A{neworder(2)}),SSVEP.(block_SSVEP_A{neworder(3)}),SSVEP.(block_SSVEP_A{neworder(4)})];
    % result4 = [SSVEP_b.(block_SSVEP_B{neworder(1)}),SSVEP_b.(block_SSVEP_B{neworder(2)}),SSVEP_b.(block_SSVEP_B{neworder(3)}),SSVEP_b.(block_SSVEP_B{neworder(4)})];

    result3 = [SSVEP.MGv];
    neworder = randperm(5);
    result4 = [SSVEP_b.(block_SSVEP_B{neworder(1)}),SSVEP_b.(block_SSVEP_B{neworder(2)}),SSVEP_b.(block_SSVEP_B{neworder(3)}),SSVEP_b.(block_SSVEP_B{neworder(4)}),SSVEP_b.(block_SSVEP_B{neworder(5)})];
    % 插入blank
    % 插入 blank 实例
    blank_struct1 = struct(...
        'location', [], ...
        'condition', 0, ...
        'stim_sequence', [], ...
        'pattern',[], ...
        'pic_idx', 5833 * ones(1, 72), ...
        'block', 'blank' ...
        );
    blank_struct2 = struct(...
        'location', [], ...
        'condition', 0, ...
        'stim_sequence', [], ...
        'pattern',[], ...
        'pic_idx', 5833 * ones(1, 52), ...
        'block', 'blank' ...
        );
    % 短的EVENT 的trial
    for i = 1:7
        neworder = randperm(4);
        if i ~= 7
            trial_win= (1:4)+(i-1)*4;
            trial_winssg = (1:52)+(i-1)*52;
        else
            trial_win = 25:27;
            trial_winssg = 313:351;
        end
        a = {};
        a{1} = Event.MGv(:,trial_win);
        a{2} = Event.MGnv(:,trial_win);
        a{3} = Event.SG(:,trial_win);
        a{4} = Event.SSGnv(:,trial_winssg);

        result5{i} = [a{neworder(1)},a{neworder(2)},a{neworder(3)},a{neworder(4)}];
    end

    num_blanks = 2;
    insert_positions1 = randperm(length(result1) + num_blanks, num_blanks);
    insert_positions1 = sort(insert_positions1);
    insert_positions2 = randperm(length(result2) + num_blanks, num_blanks);
    insert_positions2 = sort(insert_positions2);
    insert_positions3 = randperm(length(result3) + num_blanks, num_blanks);
    insert_positions3 = sort(insert_positions3);
    insert_positions4 = randperm(length(result4) + num_blanks, num_blanks);
    insert_positions4 = sort(insert_positions4);

    % 插入 blank
    for i = 1:num_blanks
        result1 = [result1(1:insert_positions1(i)-1), blank_struct2, result1(insert_positions1(i):end)];
        result2 = [result2(1:insert_positions2(i)-1), blank_struct2, result2(insert_positions2(i):end)];
        result3 = [result3(1:insert_positions3(i)-1), blank_struct1, result3(insert_positions3(i):end)];
        result4 = [result4(1:insert_positions4(i)-1), blank_struct1, result4(insert_positions4(i):end)];
    end


    final_sessions{session,1} = result1;
    pic_idx_concatenated{session,1} = [result1.pic_idx];

    final_sessions{session,2} = result2;
    pic_idx_concatenated{session,2} = [result2.pic_idx];

    final_sessions{session,3} = result3;
    pic_idx_concatenated{session,3} = [result3.pic_idx];

    final_sessions{session,4} = result4;
    pic_idx_concatenated{session,4} = [result4.pic_idx];

    for i = 1:7
        insert_positions5 = randperm(length(result5{i}) + 1, 1);
        insert_positions5 = sort(insert_positions5);
        result5{i} = [result5{i}(1:insert_positions5(1)-1), blank_struct2, result5{i}(insert_positions5(1):end)];
        final_sessions{session,4+i} = result5{i};
        pic_idx_concatenated{session,4+i} = [result5{i}.pic_idx];
    end

    disp(session);
end

%%
% save(sprintf('D:\\Ensemble coding\\sti\\GSQdata2025%s.mat',datetoday),'SSVEP',"Event");
save(sprintf('D:\\Ensemble coding\\sti\\GSQdata_session2025%s_4.mat', datetoday), 'final_sessions', "pic_idx_concatenated");

%% 构建metadata
for i = 1:20
    final_sessions{(i-1)*2+1,1} = final_sessions1{i,1};
    final_sessions{i*2,1} = final_sessions1{i,2};
    final_sessions{i,2} = final_sessions1{i,3};
    final_sessions{i,3} = final_sessions1{i,4};
    for m = 1:7
        final_sessions{(i-1)*7+m,4} = final_sessions1{i,4+m};
    end
end
for i = 1:20
    pic_idx_concatenated{(i-1)*2+1,1} = pic_idx_concatenated1{i,1};
    pic_idx_concatenated{i*2,1} = pic_idx_concatenated1{i,2};
    pic_idx_concatenated{i,2} = pic_idx_concatenated1{i,3};
    pic_idx_concatenated{i,3} = pic_idx_concatenated1{i,4};
    for m = 1:7
        pic_idx_concatenated{(i-1)*7+m,4} = pic_idx_concatenated1{i,4+m};
    end
end

%% ---------------------------GSQ------------------------------------------------------------%
clearvars -except final_sessions pic_idx_concatenated datetoday
load('D:\\Ensemble coding\\DGdata\\beforetool\\\\gsqbase.mat');
% for i = 1:10
%     pic_idx_concatenated{i,1} = pic_idx_concatenated{i,1}-3888;
% end
C = {};

Experiment = {'Event_long','SSVEP_A','SSVEP_B','Event_short'};
% Experiment = {'SSVEP_A'};
for exp = 4
    for i = 43:140
        C{1,i}(1:19,1) = D{1,1}(1:19,1);
        flash_num=length(pic_idx_concatenated{i,exp});
        %数字列
        C{1,i}(20:(19+flash_num)) = D{1,1}(20,1);
        C{1,i}((20+flash_num):(29+flash_num)) = D{1,1}(11540:11549,1);

        %整理数据
        numeric_lines = [];
        for m = 1:length(C{1,i})
            line_content = C{1,i}{m};
            if ~isempty(str2num(line_content))  % 检查行是否包含数字
                numeric_lines = [numeric_lines, m];
            end
        end
        for line_idx = 1:(size(numeric_lines,2)-1)
            numeric_line = C{1,i}{numeric_lines(line_idx)};
            values = strsplit(numeric_line, ',');
            % 修改第 10 列的值（假设从1开始计数）
            values{38} = [num2str(pic_idx_concatenated{i,exp}(line_idx)),';'];
            new_numeric_line = strjoin(values, ',');

            C{1,i}{numeric_lines(line_idx)} = new_numeric_line;
        end
        for line_idx = size(numeric_lines,2)
            % 获取当前行的数据
            numeric_line = C{1,i}{numeric_lines(line_idx)};
            values = strsplit(numeric_line, ',');
            cellArray = cellfun(@num2str, num2cell(pic_idx_concatenated{i,exp}), 'UniformOutput', false);
            values = cellArray;  % 将第 10 列的值修改为 100
            values{size(pic_idx_concatenated{i,exp},2)} = [cellArray{size(pic_idx_concatenated{i,exp},2)},';'];  % 将第 10 列的值修改为 100
            new_numeric_line = strjoin(values, ',');
            C{1,i}{numeric_lines(line_idx)} = new_numeric_line;
        end
        %修改总数

        C{1,i}(4,1) = {sprintf('SequenceLength = %d;',flash_num)};

        new_filename = sprintf('z5833%s_session%d_2025%s.GSQ',Experiment{exp},i,datetoday);

        fid = fopen(new_filename, 'w');
        for n = 1:length(C{1,i})
            fprintf(fid, '%s\n', C{1,i}{n});
        end
        fclose(fid);

        disp(['Modified data saved to ', new_filename]);

    end
end



