% ------------------------绘图----------------------------%

load('sel_channel_Yge.mat','sel_channel')
channels = sel_channel.DG;

figure('Color', 'w', 'Position', [100, 100, 1200, 500]);
tlo = tiledlayout(1, 3, 'TileSpacing', 'compact'); 

% -----------子图1：SSGnv------------------%
ax1 = nexttile(tlo);
x = fVec(1:100);
idx1 = find(DG_SSGnv_fft.meta.Condition~=-1);
idx2 = find(DG_SSGnv_fft.meta.Condition==-1);
data1 = squmean(DG_SSGnv_fft.SNR(idx1,channels,1:100),2);
data2 = squmean(DG_SSGnv_fft.SNR(idx2,channels,1:100),2);
NeuroPlot.line_with_shade(ax1, x, data1, 'Color',[0.7 0.2 0.2],'LineWidth',2);
NeuroPlot.line_with_shade(ax1, x, data2, 'Color',[0.5 0.5 0.5],'LineWidth',1);
xline(6.25,'--')
NeuroPlot.style_axis(ax1, 'Power Spectrum Density (SSGnv)', 'Frequency (Hz)', 'Power (dB)');
legend(ax1, {'Target', 'Random'});

% -----------子图2：SSGv------------------%
ax2 = nexttile(tlo);
x = fVec(1:100);
idx1 = find(DG_SSGv_fft.meta.Condition==1);
idx2 = find(DG_SSGv_fft.meta.Condition==-1);
data1 = squmean(DG_SSGv_fft.SNR(idx1,channels,1:100),2);
data2 = squmean(DG_SSGv_fft.SNR(idx2,channels,1:100),2);
NeuroPlot.line_with_shade(ax2, x, data1, 'Color',[0.7 0.2 0.2],'LineWidth',2);
NeuroPlot.line_with_shade(ax2, x, data2, 'Color',[0.5 0.5 0.5],'LineWidth',1);
xline(6.25,'--')
NeuroPlot.style_axis(ax2, 'Power Spectrum Density (SSGv)', 'Frequency (Hz)', 'Power (dB)');
legend(ax2, {'Target', 'Random'});


% ------- 子图 3: D-prime 比较 -----------%
ax3 = nexttile(tlo);
% 准备数据 Cell
dprime_group_1 = dp1;
dprime_group_2 = dp2;

NeuroPlot.bar_with_scatter(ax3, {dprime_group_1, dprime_group_2}, {'SSGnv', 'SSGv'}, ...
      'ShowSigVs0', true, ...
      'ComparePairs', [1 2]);

NeuroPlot.style_axis(ax3, 'Discrimination Ability(25hz)', '', 'd-prime');
