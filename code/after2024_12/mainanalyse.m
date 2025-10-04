%预处理：1）提取每天的数据；2）顺序重排；3）天之内去除异常trail；4）按照朝向等特征进行排列；5）normalize；6）天之间合并
%分析（MUA、LFP）：1）trail时间上展示；2）频谱分析；3）decoding；4）神经表征距离/PC空间；5）

%% 一些技巧
% 1.使用single而不是double
% 2.减少嵌套循环
% 3.使用匿名函数
% 4.使用全局变量:要记得在每一个用到这个变量的函数里面都进行全局申明，
%   不然下一个函数使用的全局变量就是没申明函数处理之前的变量
% 5.调试时候保存变量assignin('base', 'All_data_pre', All_data_pre);


global All_data



%% Session Idx
clear;
clc;

% 0815-0923；
% 0925-1113；8-ECpatch,6-oldpatch
% 1204-1213；1212-7-200ms,1213-7,var20;
session_idx_path = 'D:\\Ensemble coding\\data\\SessionIdx.mat';
load(session_idx_path);

Days = 3:5;                % day
Conditions = 6;          % condition(1-dataidx; 2-date; 3-EC; 
                         % 4-EC0; 5-SC; 6-Patch; 7-变化；8-ECPatch)
Type = 'trial_LFP';                % trial_LFP/trial_MUA

pattern = 0;                    % 是否需要pattern的计算,1是需要，其余都不是



%% ---------------------------load data-----------------------------------%
[stimID_data, Meta_data,All_data] ...
    = load_data(Days,Conditions,Type,sessionIdx,pattern);



%% ---------------------------pre analyse pic-----------------------------%
factor1 = 1;             % 1-pic;2-trail
window = -10:70;

if pattern ~= 1
    [All_data_pre,All_num,All_data] ...
        = pre_analyse(All_data, Meta_data,Days,Conditions,factor1,window);
else
    [All_data_pre,All_data,All_num_pre] = pattern_pre_analyse(All_data, Meta_data,window);
end

% Meta_data:1-ori,2-location,3-trial.

%% ---------------------------pspectrum-----------------------------------%
spectrum_factor = 1;     % 1-先频谱后平均；2-先平均后频谱
[All_Spectrum,Fa_ROI] = Spectrum_ananlyse(All_data_pre,spectrum_factor);





%% ---------------------------decoding------------------------------------%




%% ------------解码自身
model = 'PID';           % SVM/PID
condition = 1;
coilnum = 96;            % 这里使用的是按照信噪比进行
window = 1:81;
[Accuracy_all, Chance_level, True_labels, Predictions] ...
    = alldecodingcode(All_data_preEC0,condition, model, coilnum, window);

h = decodingplot(Accuracy_all, Chance_level);


%% -----------不同数据解码




%% ---------------------------MDS-----------------------------------------%
% 从4维转变为顺序排布数量相同的三维，并且要进行一定程度的重叠
% 做归一化
condition = [1,1];
coilnum = 20; 
correlationMatrix = Pcorrection(All_data_pre1,All_data_pre2,condition,coilnum);

cc = PMDS(correlationMatrix);

%% ---------------------------时间程---------------------------------------%



for x =1:15
    for y = 1:20
        All_data_pre{x,y} = cat(1,All_data_pre{x,y},All_data_pre2{x,y});
    end
end

