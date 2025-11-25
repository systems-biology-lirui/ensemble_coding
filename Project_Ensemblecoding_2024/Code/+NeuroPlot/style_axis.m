function style_axis(ax, title_str, x_label, y_label)
    if nargin > 1, title(ax, title_str, 'FontWeight', 'bold'); end
    if nargin > 2, xlabel(ax, x_label); end
    if nargin > 3, ylabel(ax, y_label); end
    
    set(ax, 'FontSize', 12, 'LineWidth', 1.2, 'TickDir', 'out');
    box(ax, 'off'); % 经典的科研绘图风格，去除右侧和上侧边框
end