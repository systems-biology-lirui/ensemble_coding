function [SSVEP,Event] = GSQ_feature2picID(SSVEP,Event)
% -----------------------------feature2picID-----------------------------%

clearvars -except Event SSVEP blocks datetoday;
% load('D:\\Ensemble coding\\data\\PatchvarSequence.mat','target90','target10','random');
% 构建新的刺激库，
% 1-3888 SSGv；
% 3889-5292 SSGnv；
% 5293-5400 SG；
% 5401-5508 MGnv；
% 5509-5832MGv；
% 5833 blank；

% MGv
if isfield(SSVEP,'MGv')
    for i = 1:size([SSVEP.MGv.condition],2)
        if SSVEP.MGv(i).condition ~= 0
            SSVEP.MGv(i).pic_idx = 5508 + (SSVEP.MGv(i).stim_sequence-1)*18+(SSVEP.MGv(i).pattern-1)*3+1;
        else
            SSVEP.MGv(i).pic_idx = 5508 + ones(1,72)*325;
        end
        SSVEP.MGv(i).block = 'MGv';
    end
end
if isfield(Event,'MGv')
    for i = 1:size(Event.MGv,2)
        if any(Event.MGv(i).stim_sequence,'all')
            for pic = 1:52
                if Event.MGv(i).stim_sequence(pic) == 0
                    Event.MGv(i).pic_idx(pic) = 5833;
                else
                    Event.MGv(i).pic_idx(pic) = 5508 + (Event.MGv(i).stim_sequence(pic)-1)*18+(Event.MGv(i).pattern(pic)-1)*3+1;
                end
            end
        else
            Event.MGv(i).pic_idx = 5508 + ones(1,52)*325;
            Event.MGv(i).condition = 0;
        end
        Event.MGv(i).block = 'MGv';
    end
end

% MGnv
if isfield(SSVEP,'MGnv')
    for i = 1:size([SSVEP.MGnv.condition],2)
        if SSVEP.MGnv(i).condition ~= 0
            SSVEP.MGnv(i).pic_idx = 5400 + (SSVEP.MGnv(i).stim_sequence-1)*1+(SSVEP.MGnv(i).pattern-1)*18+1;
        else
            SSVEP.MGnv(i).pic_idx = 5508 + ones(1,72)*325;
        end
        SSVEP.MGnv(i).block = 'MGnv';
    end
end
if isfield(Event,'MGnv')
    for i = 1:size(Event.MGnv,2)
        if any(Event.MGnv(i).stim_sequence,'all')
            for pic = 1:52
                if Event.MGnv(i).stim_sequence(pic) == 0
                    Event.MGnv(i).pic_idx(pic) = 5833;
                else
                    Event.MGnv(i).pic_idx(pic) = 5400 + (Event.MGnv(i).stim_sequence(pic)-1)*1+(Event.MGnv(i).pattern(pic)-1)*18+1;
                end
            end
        else
            Event.MGnv(i).pic_idx = 5508 + ones(1,52)*325;
            Event.MGnv(i).condition = 0;
        end
        Event.MGnv(i).block = 'MGnv';
    end
end
% SG
if  isfield(SSVEP,'SG')
    for i = 1:size([SSVEP.SG.condition],2)
        if SSVEP.SG(i).condition ~= 0
            SSVEP.SG(i).pic_idx = 5292 + (SSVEP.SG(i).stim_sequence-1)*1+(SSVEP.SG(i).pattern-1)*18+1;
        else
            SSVEP.SG(i).pic_idx = 5508 + ones(1,72)*325;
        end
        SSVEP.SG(i).block = 'SG';
    end
end
if isfield(Event,'SG')
    for i = 1:size(Event.SG,2)
        if any(Event.SG(i).stim_sequence,'all')
            for pic = 1:52
                if Event.SG(i).stim_sequence(pic) == 0
                    Event.SG(i).pic_idx(pic) = 5833;
                else
                    Event.SG(i).pic_idx(pic) = 5292 + (Event.SG(i).stim_sequence(pic)-1)*1+(Event.SG(i).pattern(pic)-1)*18+1;
                end
            end

        else
            Event.SG(i).pic_idx = 5508 + ones(1,52)*325;
            Event.SG(i).condition = 0;
        end
        Event.SG(i).block = 'SG';
    end
end
% SSGnv
if isfield(SSVEP,'SSGnv')
    for i = 1:size([SSVEP.SSGnv.condition],2)
        if SSVEP.SSGnv(i).condition ~= 0
            SSVEP.SSGnv(i).pic_idx = 3888 + (SSVEP.SSGnv(i).stim_sequence-1)*1+randi([0,5])*18+(SSVEP.SSGnv(i).location-1)*108+1;
        else
            SSVEP.SSGnv(i).pic_idx = 5508 + ones(1,72)*325;
        end
        SSVEP.SSGnv(i).block = 'SSGnv';
    end
end
if isfield(Event,'SSGnv')
    for i = 1:size(Event.SSGnv,2)
        if any(Event.SSGnv(i).stim_sequence,'all')
            for pic = 1:52
                if Event.SSGnv(i).stim_sequence(pic) == 0
                    Event.SSGnv(i).pic_idx(pic) = 5833;
                else
                    Event.SSGnv(i).pic_idx(pic) = 3888 + (Event.SSGnv(i).stim_sequence(pic)-1)*1+randi([0,5])*18+(Event.SSGnv(i).location-1)*108+1;
                end
            end
        else
            Event.SSGnv(i).pic_idx = 5508 + ones(1,52)*325;
            Event.SSGnv(i).condition = 0;
        end
        Event.SSGnv(i).block = 'SSGnv';
    end
end