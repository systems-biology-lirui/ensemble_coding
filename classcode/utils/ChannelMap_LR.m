function ChannelMap_LR(data, macaque, plot_type, x_values, y_values)
% ChannelMap_LR 绘制对应位置的channel plot，支持线图或热图，并可为热图添加坐标轴。
%
% 语法:
%   ChannelMap_LR(data, macaque, 'line', x_values)
%   ChannelMap_LR(data, macaque, 'heatmap', x_values, y_values)
%
% 输入参数:
%   data - 绘图数据。
%          - 'line'模式: 2D 矩阵 [channel, time/value] 或 3D 矩阵 [channel, series, time/value]。
%          - 'heatmap'模式: 3D 矩阵 [channel, Y_dim, X_dim] (例如: channel x freq x time)。
%
%   macaque - 猴子名称，字符串 "QQ" 或 "DG"。
%
%   plot_type - 绘图类型，字符串 "line" 或 "heatmap"。
%
%   x_values - (可选) X轴坐标。
%              - 'line'模式: 必需，长度应等于 size(data, end)。
%              - 'heatmap'模式: 可选，长度应等于 size(data, 3)。
%
%   y_values - (可选) Y轴坐标。
%              - 'line'模式: 不使用。
%              - 'heatmap'模式: 可选，长度应等于 size(data, 2)。

% --- 1. 参数验证和默认值设定 ---
arguments
    data (:,:,:) {mustBeNumeric}
    macaque (1,1) string {mustBeMember(macaque, ["QQ", "DG"])}
    plot_type (1,1) string {mustBeMember(plot_type, ["line", "heatmap"])}
    x_values (1,:) {mustBeNumeric} = []
    y_values (1,:) {mustBeNumeric} = []
end

% 获取数据维度信息
data_dims = size(data);
num_channels = data_dims(1);

% --- 2. 详细参数校验 ---
if plot_type == "line"
    % 在 line 模式下，时间/值维度是 data 的最后一维
    time_dim_size = data_dims(end); 
    
    if isempty(x_values)
        error('对于线图 (plot_type="line")，必须提供 x_values。');
    end
    if length(x_values) ~= time_dim_size
        error('x_values 的长度 (%d) 与数据最后一维的长度 (%d) 不匹配。', length(x_values), time_dim_size);
    end

    % 确定线条数量：如果是 2D 数据，线条数量为 1；如果是 3D，线条数量为第二维大小
    if ndims(data) == 2
        num_series = 1;
        % 确保 data 在内部处理时仍被视为 3D (1个系列)
        data = reshape(data, [num_channels, 1, time_dim_size]); 
    else % ndims(data) == 3
        num_series = data_dims(2);
    end

elseif plot_type == "heatmap"
    % heatmap 模式要求数据必须是 3D (channel x Y_dim x X_dim)
    if ndims(data) < 3
        error('对于热图 (plot_type="heatmap")，数据必须至少是 3D 矩阵 [channel, Y_dim, X_dim]。');
    end
    
    y_dim_size = data_dims(2);
    x_dim_size = data_dims(3);

    if ~isempty(x_values) && length(x_values) ~= x_dim_size
        error('x_values 的长度 (%d) 与数据第三维的长度 (%d) 不匹配。', length(x_values), x_dim_size);
    end
    if ~isempty(y_values) && length(y_values) ~= y_dim_size
        error('y_values 的长度 (%d) 与数据第二维的长度 (%d) 不匹配。', length(y_values), y_dim_size);
    end
end


% --- 3. 根据动物设置特定参数 ---
highlight_channels = [];
switch macaque
    case "DG"
        map_file = 'D:\ensemble_coding\DGdata\tooldata\DGChannelMap.mat';
        map_var_name = 'DGchannelMap';
    case "QQ"
        map_file = 'D:\ensemble_coding\QQdata\tooldata\QQChannelMap.mat';
        map_var_name = 'QQchannelMap';
        % 假设这个路径下的文件是存在的
        highlight_data = load('D:\ensemble_coding\QQdata\tooldata\QQchannelselect.mat', 'selected_coil_final');
        highlight_channels = highlight_data.selected_coil_final;
end
highlight_channels = [74	67	68	72	45	38	40	86	7	87	58	91	92	25	94	29	64	61	56	30];
try
    chanmap_struct = load(map_file);
    chanmap = chanmap_struct.(map_var_name);
catch ME
    error('无法加载通道映射文件: %s\n%s', map_file, ME.message);
end

% --- 4. 开始绘图 ---
figure;
sgtitle(sprintf('Channel Map for %s (%s plot)', macaque, plot_type));


if num_channels > 96
    fprintf('警告: 输入数据有 %d 个通道，但只会绘制前96个通道。\n', num_channels);
    num_channels_to_plot = 96;
else
    num_channels_to_plot = num_channels;
end

% 定义多线条模式下的颜色 (使用 'lines' 颜色图确保颜色较深且对比度高)
if plot_type == "line" && num_series > 1
    % lines 颜色图专门为多线条设计，提供深色、高对比度的颜色。
    % 如果 num_series 超过默认的 lines 颜色数量，颜色将循环。
    line_colors = lines(max(num_series, 7)); % 确保至少使用7种颜色以获得好的区分度
    line_colors = line_colors(1:num_series, :); % 截取所需数量
elseif plot_type == "line" && num_series == 1
    % 单条线，高亮逻辑在循环内处理
    line_colors = [];
end


for i = 1:num_channels_to_plot
    % 找到通道 i 在 10x10 网格中的位置 n
    n = find(chanmap' == i, 1);
    if isempty(n), continue; end % 如果通道 i 不在映射中，跳过
    
    subplot(10, 10, n);
    hold on;
   
    is_highlighted = ismember(i, highlight_channels);
    
    % --- 5. 根据 plot_type 执行不同的绘图命令 ---
    switch plot_type
        case "line"
            
            % 提取当前通道的数据 (series x time)
            channel_data = squeeze(data(i, :, :)); 
            
            if num_series == 1
                % 单线模式
                plot_color = 'b';
                if is_highlighted, plot_color = 'r'; end
                plot(x_values, channel_data, 'Color', plot_color, 'LineWidth', 1.5);
            else
                % 多线模式
                for k = 1:num_series
                    plot(x_values, channel_data(k, :), 'Color', line_colors(k, :), 'LineWidth', 1);
                end
            end
            
            % 可选：美化线图坐标轴
            % 自动调整Y轴范围，避免数据被裁剪
            if ~isempty(channel_data)
                min_val = min(channel_data(:));
                max_val = max(channel_data(:));
                ylim([min_val - (max_val - min_val)*0.1, max_val + (max_val - min_val)*0.1]);
            end
            
        case "heatmap"
            % 提取当前通道的数据 (Y_dim x X_dim)
            plot_data = squeeze(data(i, :, :));
            
            % 根据是否提供了坐标轴数据，选择不同的 imagesc 调用方式
            if ~isempty(x_values) && ~isempty(y_values)
                imagesc(x_values, y_values, plot_data);
            elseif ~isempty(x_values) % 只提供了x轴
                imagesc(x_values, 1:size(plot_data,1), plot_data);
            else % 未提供任何坐标轴，使用默认像素索引
                imagesc(plot_data);
            end
            
            set(gca, 'YDir', 'normal'); % 使Y轴从下到上递增
            % 对于热图，可能需要设置一个全局的 Caxis (在循环外获取 min/max(data) 是更好的做法)
            
    end
    
    % --- 6. 坐标轴和标题设置 ---
    
    % 移除除外围之外的坐标轴刻度标签，使图清晰
    % 检查 n 是否在地图边缘
    [r, c] = find(chanmap' == i); % 找到在 10x10 网格中的行和列
    
    if r < 10 % 不是最下面一行，移除X轴标签
        set(gca, 'XTickLabel', []);
    end
    if c > 1 % 不是最左边一列，移除Y轴标签
        set(gca, 'YTickLabel', []);
    end

    % 设置子图标题 (通道号)
    title_color = 'k';
    title_weight = 'normal';
    if is_highlighted
        title_color = 'r';
        title_weight = 'bold';

    end
    title(num2str(i), 'Color', title_color, 'FontWeight', title_weight, 'FontSize', 8);
    box off
    hold off;
end

% 对于热图，添加颜色条
if plot_type == "heatmap"
    cb = colorbar;
    cb.Location = 'eastoutside';
end

end