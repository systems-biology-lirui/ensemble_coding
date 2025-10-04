function fftanalyse_plot(condsel,file_idx,Labels,Colors,selected_coil_final,plot_content_savepath)
% 进行频谱的计算
% 输入：
%   文件目录，标签，颜色
% 输出：
%   频谱和相位结果图；
%   不同条件d-prime柱状图（6.25hz，25hz）
%   

for n = 1:length(file_idx)
    frequences = [21,41,81]; % 分别是6.25，12.5，25hz
    clear fftresult 
    clear dprimeresult
    data = load(file_idx{n});
    channum = size(data.(Labels{n})(1).Data,2);
    % 非SSG条件
    if ~strcmp(Labels{n},'SSGnv') && ~ strcmp(Labels{n},'SSGv')

        % 频谱
        fftresult.(Labels{n}) = cell(2,10);
        dprimeresult.(Labels{n}) = {};
        for cond = [1,condsel]
            if ~isempty(data.(Labels{n})(cond).Data)
                currentdata = single(data.(Labels{n})(cond).Data(1:101,:,:));
%                 errordata = reshape(currentdata,[9,5,94,1640]);
%                 currentdata = squmean(errordata,2);
                [P1_3d,Phase_3d,f] = SSVEP_fftanalyse(currentdata);
                fftresult.(Labels{n}){1,cond} = P1_3d;
                fftresult.(Labels{n}){2,cond} = Phase_3d;
            end
        end

        % 计算dprime
        noise_ssvep = fftresult.(Labels{n}){1,1}(:,:,frequences);
        target_ssvep = zeros(1,channum,size(noise_ssvep,3));
        for cond = condsel
            target_ssvep = target_ssvep+fftresult.(Labels{n}){1,cond}(:,:,frequences);
        end
        target_ssvep = target_ssvep/length(condsel);
        dprimeresult.(Labels{n}){1}= SSVEP_dprime(noise_ssvep,target_ssvep);
        
        % 计算dprime
        noise_phase = fftresult.(Labels{n}){2,1}(:,:,frequences);
        target_phase = zeros(1,channum,size(noise_phase,3));
        for cond = condsel
            target_phase = target_phase+fftresult.(Labels{n}){2,cond}(:,:,frequences);
        end
        target_phase = target_phase/length(condsel);
        dprimeresult.(Labels{n}){2}= SSVEP_dprime(noise_phase,target_phase);

        % 绘制不同条件的频谱结果与相位结果
        % 频谱
%         figure;
%         subplot(1,2,1);
        % random
        random_am = mean(squmean(fftresult.(Labels{n}){1,1}(:,selected_coil_final,1:100),1),1);
%         plot(f(1:100),10*log10(random_am),'LineWidth',1.3,'Color',[0.7,0.7,0.7]);
%         hold on
        % target90
        target_am = [];
        for cond = condsel
        target_am = cat(1,target_am,fftresult.(Labels{n}){1,cond}(:,selected_coil_final,1:100));
        end
        target_am = squmean(target_am,[1,2]);
%         plot(f(1:100),10*log10(target_am),'LineWidth', 2 ,'Color',Colors(n,:));
%         hold off
%         xline(6.25,'--');
%         xline(25,'--');
%         subtitle(sprintf('Amplitude %s',Labels{n}));

        % 相位
%         subplot(1,2,2);
        random_ph = mean(squmean(fftresult.(Labels{n}){2,1}(:,selected_coil_final,1:100),1),1);
%         plot(f(1:100),random_ph,'LineWidth',1.3,'Color',[0.7,0.7,0.7]);
%         hold on
        target_ph = [];
        for cond = condsel
            target_ph = cat(1,target_ph,fftresult.(Labels{n}){2,cond}(:,selected_coil_final,1:100));
        end
        target_ph = squmean(target_ph,[1,2]);
%         plot(f(1:100),target_ph,'LineWidth', 2 ,'Color',Colors(n,:));
%         hold off
%         xline(6.25,'--');
%         xline(25,'--');
%         subtitle(sprintf('Phase %s',Labels{n}));
    
    % SSG条件
    else
        fftresult.(Labels{n}) = cell(2,13,10);
        dprimeresult.(Labels{n}) = zeros(2,94);
        condition = -1:2:17;
        for loc = 1:12
            for cond = condsel
                idx = find([data.(Labels{n}).Location] == loc & [data.(Labels{n}).Target_Ori] == condition(cond));
                if ~isempty(data.(Labels{n})(idx).Data)
                    currentdata = single(data.(Labels{n})(idx).Data);
                    [P1_3d,Phase_3d,f] = SSVEP_fftanalyse(currentdata);
                    fftresult.(Labels{n}){1,loc,cond} = P1_3d;
                    fftresult.(Labels{n}){2,loc,cond} = Phase_3d;
                end
            end
        end

        % 计算d-prime
        noise_ssvep = squmean(cat(4,fftresult.(Labels{n}){1,1:12,1}(:,:,frequences)),4);
        target_ssvep = squmean(cat(4,fftresult.(Labels{n}){1,1:12,6}(:,:,frequences)),4);
        dprimeresult.(Labels{n})= SSVEP_dprime(noise_ssvep,target_ssvep);

        % 绘制不同条件的频谱结果与相位结果
        % 频谱
        figure;
        subplot(1,2,1);
        % random
        random_am = mean(squmean(fftresult.(Labels{n}){1,13,1}(:,selected_coil_final,1:100),1),1);
        plot(f(1:100),random_am,'LineWidth',1.3,'Color',[0.7,0.7,0.7]);
        hold on
        % target90
        target_am = mean(squmean(fftresult.(Labels{n}){1,13,6}(:,selected_coil_final,1:100),1),1);
        plot(f(1:100),target_am,'LineWidth', 2 ,'Color',Colors(n,:));
        hold off
        xline(6.25,'--');
        xline(25,'--');
        subtitle(sprintf('Amplitude %s',Labels{n}));

        % 相位
        subplot(1,2,2);
        random_ph = mean(squmean(fftresult.(Labels{n}){2,13,1}(:,selected_coil_final,1:100),1),1);
        plot(f(1:100),random_ph,'LineWidth',1.3,'Color',[0.7,0.7,0.7]);
        hold on
        target_ph = mean(squmean(fftresult.(Labels{n}){2,13,6}(:,selected_coil_final,1:100),1),1);
        plot(f(1:100),target_ph,'LineWidth', 2 ,'Color',Colors(n,:));
        hold off
        xline(6.25,'--');
        xline(25,'--');
        subtitle(sprintf('Phase %s',Labels{n}));

    end
    [~,file_name,~] = fileparts(file_idx{n});

    plot_content.(Labels{n}).random_am = random_am;
    plot_content.(Labels{n}).target_am = target_am;
    
    plot_content.(Labels{n}).random_ph = random_ph;
    plot_content.(Labels{n}).target_ph = target_ph;

    plot_content.(Labels{n}).dprimeresult = dprimeresult.(Labels{n});
    
    save(sprintf('fftresult_1A_%s_%s.mat',file_name(1:2),Labels{n}),"dprimeresult");
    % save(sprintf('D:\\Ensemble plot\\QQ\\fftresult_%s.mat',Labels{n}),'fftresult',"dprimeresult");

end

save(sprintf('%s.mat',plot_content_savepath),"plot_content");

% % 绘制不同条件dprime柱状图
% figure;
% dprimeplot = [];
% for n = 1:n_conditions
%     dprimeplot = cat(3,dprimeplot,dprimeresult.(Labels{n}));
% end
% dprimeplot = dprimeplot(:,selected_coil_final,:);
% % 计算每个子组的均值
% mean_data = squeeze(mean(dprimeplot, 2)); 
% hold on;
% 
% % 设置柱状图的位置
% x = 1:n_conditions; 
% offset = 0.2; 
% 
% % 6.25hz
% bar(x - offset, mean_data(1, :), 0.4, 'FaceColor', [0.2, 0.6, 1]); 
% scatter(repmat(x - offset, 94, 1), squeeze(dprimeplot(1, :, :)), 10, 'k', 'filled'); 
% 
% % 25hz
% bar(x + offset, mean_data(2, :), 0.4, 'FaceColor', [1, 0.6, 0.2]); 
% scatter(repmat(x + offset, 94, 1), squeeze(dprimeplot(2, :, :)), 10, 'k', 'filled'); 
% 
% % 设置图形属性
% set(gca, 'XTick', x); 
% set(gca, 'XTickLabel', Labels); 
% title('D-prime');
% legend('6.25hz', '25hz');
% hold off;
% box off