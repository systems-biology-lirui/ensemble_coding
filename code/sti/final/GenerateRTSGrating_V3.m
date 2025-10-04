function GenerateRTSGrating_V3(handles)
%%% Fixation information not included!

global StimInfo;

TotalStimNum = size(StimInfo.PrintedStim,1);
PatchNum = StimInfo.GlobalParam.PatchNum;
% BlankNum = StimInfo.GlboalParam.BlankNum;

BasicParamNum = length(fieldnames(StimInfo.BasicParam(1)));
% MoreParamIndex1 = length(StimInfo.PrintedParam)-PatchNum*BasicParamNum+1;
MoreParamIndex1 = PatchNum*BasicParamNum+1;
MoreParamIndex2 = length(StimInfo.PrintedParam);

FilePath = StimInfo.GlobalParam.FilePath;
FileName = StimInfo.GlobalParam.FileName;
FileDir = [FilePath,'\',FileName(1:end-4)];

%% Image generating
tstart = tic;
for ii = 1:TotalStimNum
    if mod(ii,1000) == 1
        telapsed = ceil(toc(tstart));
        tstart = tic;
        disp([num2str(ii),' out of ',num2str(TotalStimNum),' BMP generated --- Elapsed time = ',num2str(telapsed),' seconds; ']);
    else
        if ii == TotalStimNum
            telapsed = ceil(toc(tstart));
            disp([num2str(ii),' out of ',num2str(TotalStimNum),' BMP generated --- Elapsed time = ',num2str(telapsed),' seconds. ']);
        end
    end
    
    for jj = MoreParamIndex1:MoreParamIndex2
        cmd = [StimInfo.PrintedParam{jj},' = StimInfo.PrintedStim(ii,jj);'];
        eval(cmd);
    end
    
    %     XPixel = round(BMPXSize*StimInfo.Degree2Pixel);
    %     YPixel = round(BMPYSize*StimInfo.Degree2Pixel);
    XPixel = round(BMPXSize*StimInfo.Degree2Pixel/4)*4;
    YPixel = round(BMPYSize*StimInfo.Degree2Pixel/4)*4;
    [xx,yy] = meshgrid(1:XPixel,1:YPixel);
    xx = xx/XPixel*BMPXSize; xx = xx - mean(xx(:)) + BMPXPos;
    yy = yy/YPixel*BMPYSize; yy = yy - mean(yy(:)) + BMPYPos;

    for jj = 1:PatchNum
        for kk = 1:BasicParamNum
            CurrParam = StimInfo.PrintedParam{kk+(jj-1)*BasicParamNum}(1:end-2);
            cmd = [CurrParam,' = StimInfo.PrintedStim(ii,kk+(jj-1)*BasicParamNum);'];
            eval(cmd);
        end
        
        FixRegion = sqrt((xx-FixXPos).^2+(yy-FixYPos).^2) < FixRadius;
        if StimInfo.BasicParam(jj).XSize{6} >= 0
        else
            XSize = Radius;
            YSize = Radius;
        end
        
        if Contrast == 0
            if strcmp(StimInfo.GlobalParam.ColorType,'Indexed')
                CurrImg = ones(size(xx,1),size(xx,2))*1.1;
            else
                CurrImg = ones(size(xx,1),size(xx,2))*BackLum;
                StimR = BackR;
                StimG = BackG;
                StimB = BackB;
            end
            StimRegion = double(abs(xx-XPos) <= XSize/2) .* double(abs(yy-YPos) <= YSize/2);
        else
            %%% Image calculating
            CurrValue = 2*pi*(sin(Ori/180*pi)*yy + cos(Ori/180*pi)*xx);
            CurrValue = SF*CurrValue;
            switch Aperture
                case 1
                    CurrImg = (1+sin(CurrValue+SPhase/180*pi)*Contrast)*StimLum;
                    StimRegion = double(abs(xx-XPos) <= XSize/2) .* double(abs(yy-YPos) <= YSize/2);
                    if NegBit == 2
                        StimRegion = 1-StimRegion;
                    end
                case 2
                    CurrImg = (1+sin(CurrValue+SPhase/180*pi)*Contrast)*StimLum;
                    StimRegion = sqrt((YSize/2*(xx-XPos)).^2+(XSize/2*(yy-YPos)).^2) <= XSize/2*YSize/2;
                    if NegBit == 2
                        StimRegion = 1-StimRegion;
                    end
                case 3
                    CurrGabor = exp(-((xx-XPos).^2/(2*Sigma.^2)+((yy-YPos).^2/(2*Sigma.^2))));
                    CurrImg = (1+CurrGabor.*sin(CurrValue+SPhase/180*pi)*Contrast)*StimLum;
                    StimRegion = sqrt((YSize/2*(xx-XPos)).^2+(XSize/2*(yy-YPos)).^2) <= XSize/2*YSize/2;
                    if NegBit == 2
                        StimRegion = 1-StimRegion;
                    end
            end
%             StimRegion = StimRegion-StimRegion.*FixRegion;
        end
        StimRegion = StimRegion-StimRegion.*FixRegion;
        
        if SProfile == 2 %%% Square Wave
            MaxValue = max(CurrImg(:));
            MinValue = min(CurrImg(:));
            HalfValue = (MaxValue+MinValue)/2;
            CurrImg(CurrImg > HalfValue) = MaxValue;
%             CurrImg(CurrImg <= HalfValue) = MinValue;
            CurrImg(CurrImg <= HalfValue) = MinValue+0.0015;
        else
        end
        
         %%% Indexed map when colortype is indexed; StimR/G/B and
        %%% BackR/G/B have actually only one valid value;
        if strcmp(StimInfo.GlobalParam.ColorType,'Indexed')
            if jj == 1
                BMPImg = CurrImg.*StimRegion;
%                 BMPImg = CurrImg.*(1-StimRegion);
                BMPRegion = StimRegion;
            else
                StimRegion(find(BMPImg~=0))=0;
                BMPImg = BMPImg+CurrImg.*StimRegion;
                BMPRegion = BMPRegion+StimRegion;
            end
            
%             if ii+jj == 2
                StimRGB = [StimR,StimG,StimB];   %% Added by DWF on 27/10//2014
                BackRGB = BackLum*[BackR,BackG,BackB];
                FixRGB = FixLum*[FixR,FixG,FixB];
                
                CurrMap = (0:255)'*[1,1,1];
                
                CurrMap(1,:) = BackRGB;
                CurrMap(2:201,:) = (CurrMap(2:201,:)-1)/200.*repmat(StimRGB,200,1);
                CurrMap(202:256,:) = repmat(CurrMap(1,:),55,1);
                CurrMap(226:235,:) = repmat(FixRGB,10,1);
                
                if ConeIsolate > 0
                    LMSCoeValid = ConeIsolation(BackRGB);
                    switch ConeIsolate
                        case 1
                            CurrCoeValid = LMSCoeValid.LCoeValid;
                        case 2
                            CurrCoeValid = LMSCoeValid.MCoeValid;
                        case 3
                            CurrCoeValid = LMSCoeValid.SCoeValid;
                    end
                    CurrMap(2:201,:) = CurrCoeValid(:,floor(linspace(1,length(CurrCoeValid),200)))';
                end
%             end
        else
            if jj == 1
                TrueClrImg(:,:,1) = CurrImg.*StimRegion*StimR;
                TrueClrImg(:,:,2) = CurrImg.*StimRegion*StimG;
                TrueClrImg(:,:,3) = CurrImg.*StimRegion*StimB;
                BMPRegion = StimRegion;
            else
                TrueClrImg(:,:,1) = TrueClrImg(:,:,1)+CurrImg.*StimRegion*StimR;
                TrueClrImg(:,:,2) = TrueClrImg(:,:,2)+CurrImg.*StimRegion*StimG;
                TrueClrImg(:,:,3) = TrueClrImg(:,:,3)+CurrImg.*StimRegion*StimB;
                BMPRegion = BMPRegion+StimRegion;
            end
        end
%         
%         if jj == 1
%             BMPImg = CurrImg.*StimRegion;
%             BMPRegion = StimRegion;
%         else
%             BMPImg = BMPImg+CurrImg.*StimRegion;
%             BMPRegion = BMPRegion+StimRegion;
%         end
%         
%         %%% Indexed map when colortype is indexed; StimR/G/B and
%         %%% BackR/G/B have actually only one valid value;
%         if strcmp(StimInfo.GlobalParam.ColorType,'Indexed') && ii+jj == 2
%             StimRGB = [StimR,StimG,StimB];   %% Added by DWF on 27/10//2014
%             BackRGB = BackLum*[BackR,BackG,BackB];
%             CurrMap = (0:255)'*[1,1,1];
%             
%             CurrMap(1,:) = BackRGB;
%             CurrMap(2:201,:) = (CurrMap(2:201,:)-1)/200.*repmat(StimRGB,200,1);
%             CurrMap(202:256,:) = repmat(CurrMap(1,:),55,1);
%         elseif strcmp(StimInfo.GlobalParam.ColorType,'TrueColor')
%             if jj == 1
%                 TrueClrImg(:,:,1) = BMPImg*StimR;
%                 TrueClrImg(:,:,2) = BMPImg*StimG;
%                 TrueClrImg(:,:,3) = BMPImg*StimB;
%             else
%                 TrueClrImg(:,:,1) = TrueClrImg(:,:,1)+BMPImg*StimR;
%                 TrueClrImg(:,:,2) = TrueClrImg(:,:,2)+BMPImg*StimG;
%                 TrueClrImg(:,:,3) = TrueClrImg(:,:,3)+BMPImg*StimB;
%             end
%         end
    end
    
    %     if BlankNum ~= 0
    %         buf = sprintf('%010ld',ii-1);
    %     else
    %         buf = sprintf('%010ld',ii);
    %     end
    %
    buf = sprintf('%010ld',StimID);
    BMPRegion(BMPRegion > 1) = 1;
    
    if strcmp(StimInfo.GlobalParam.ColorType,'Indexed')
        %         BMPImg > 1 == 1;
        
        %         SavedImg = BMPImg+(1-BMPRegion)*BackLum;
        %         SavedImg = BMPImg+(1-BMPRegion)*1.1;
%         SavedImg = BMPImg+(1-BMPRegion-FixRegion)*1.1+FixLum*FixRegion;
        SavedImg = BMPImg+(1-BMPRegion-FixRegion)*1.1+FixRegion*1.15;
        SavedImg = SavedImg * 200 + 1;
        SavedImg = uint8(SavedImg);
        imwrite(SavedImg,CurrMap,[FileDir,'\',buf,'.bmp'],'bmp');
    else
        TrueClrBkgr(:,:,1) = (1-BMPRegion-FixRegion)*BackR*BackLum;
        TrueClrBkgr(:,:,2) = (1-BMPRegion-FixRegion)*BackG*BackLum;
        TrueClrBkgr(:,:,3) = (1-BMPRegion-FixRegion)*BackB*BackLum;
        
        TrueClrFix(:,:,1) = FixRegion*FixR*FixLum;
        TrueClrFix(:,:,2) = FixRegion*FixG*FixLum;
        TrueClrFix(:,:,3) = FixRegion*FixB*FixLum;
        
%         SavedImg = TrueClrImg/2+TrueClrBkgr+TrueClrFix;
        SavedImg = TrueClrImg+TrueClrBkgr+TrueClrFix;
        imwrite(SavedImg,[FileDir,'\',buf,'.bmp'],'bmp');
    end
end
end