%% ----------------汇总整理数据（trial）--------------------%
% ---------------------------------------------------------%
currentPath = fileparts(mfilename('fullpath')); % Code/Scripts
rootPath = fileparts(fileparts(currentPath));   % Project Root
addpath(genpath(fullfile(rootPath, 'Code')));   % 加入 Code 路径

config = Main_Config();
builder = NeuroDB.Builder(config);
builder.run();


%% ------------------trial水平的处理----------------------- %
% ---------------------------------------------------------%
clear;
macaques = {'DG','QQ_old','QQ_new'};
labels = {'MGv'};
for m = 1:length(macaques)
    for l = 1:length(labels)
        dbPath = 'D:/ensemble_coding/Project_Ensemblecoding_2024/Data/01_Database';
        analyzer = NeuroDB.NeuroAnalyzer(macaques{m}, labels{l}, 'EVENT', 'LFP', dbPath);
        % 由于SSGnv实在是太多了，只选取和SSGv同样的数量进行（DG：61session）
        % analyzer.subset_sessions(61);
        % analyzer.subset_data('Condition', [-1, 1, 9]);


        % ---------------------预处理-------------------------------%
        % ---------------------------------------------------------%
        % 1.减去baseline（从trial提取epoch应该用trial前作为baseline）
        baseline = mean(analyzer.RawTensor(:,:,1:100),3);
        analyzer.RawTensor = analyzer.RawTensor - int16(baseline);
        % 2.进行滤波
        % 3.如有必要，SSGv需要使用getSSGvpattern

        if ~strcmp(analyzer.BlockName,'SSGv') & ~strcmp(analyzer.BlockName,'SSGnv')
            for i = 1:height(analyzer.MetaTable)
                analyzer.MetaTable.Location(i) = 0;
            end
        end
        [~, ~] = analyzer.slice_epochs('SingleTrials',true ,'Save', true);
    end
end
%%
analyzer.filter_raw_data()

%% ---------------------频谱分析-----------------------------%
% ---------------------------------------------------------%
% 1.fft
% 2.d-prime
% --------------1.fft----------------%
% 模式 A: 默认模式 (Session内平均 -> PSD)，并计算 SNR
[psdData, fVec, info] = analyzer.analyze_spectrum(...
    'Method', 'Default', ...
    'ComputeSNR', true);

% psdData: [nGroups, nCh, nFreq]
% info.Meta: 对应的元数据 (包含 Date, Session, Location 等)
% info.SNR:  [nGroups, nCh, nFreq] (信噪比谱)

fftresult.dg.ssgnv.psdData = psdData;
fftresult.dg.ssgnv.meta = info.Meta;
fftresult.dg.ssgnv.SNR = info.SNR;
%% ------------ 2.d-prime ------------%
% 这个做的不太行
[dp1, ~] = analyzer.analyze_dprime(DG_SSGnv_fft.SNR(:,channels,:), info.Meta, fVec, 25);
[dp2, stats] = analyzer.analyze_dprime(DG_SSGv_fft.SNR(:,channels,:), info.Meta, fVec, 25);



%% -------------------进行切片（PIC）-----------------------%
% [avgEpochs, avgMeta] = analyzer.slice_epochs('AverageRepeats', true, 'Save',true);
[data, meta] = analyzer.slice_epochs('CollapseToCount', 13, 'Save', true);
% CollapseToCount会强制先进行sessionavg，原本QQ_ssgv_b有134个
head(meta)


%% 2. 初始化 QC
qc = NeuroQC.Analyzer(EpochDB.Data, EpochDB.Meta, 500);

% 3. 执行检查
qc.detect_bad_trials('Threshold', 300);       % 剔除 >300uV 的试次
qc.check_channel_correlation('Threshold', 0.1); % 检查坏通道

% 4. 展示结果
qc.plot_amplitude_dist();      % 看看数据分布
qc.plot_correlation_matrix();  % 看看通道好坏
qc.plot_psth_by_condition('PicID'); % 看看不同刺激下的波形 (朝向选择性)

% -------------------进行切片（PIC）-----------------------%
% ---------------------------------------------------------%
%% --------------------Decoding-----------------------------%
% ----------------------SSVEP_A-----------------------------%
%------------orientation-------------%




% ----------------------SSVEP_B-----------------------------%
%----------------拟合-----------------%




%-------------decoding----------------%
