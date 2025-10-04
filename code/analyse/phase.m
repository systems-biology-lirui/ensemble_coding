%% 
figure(3)
for i =1:9
    
    data = mean(mean(all_orient_data_EC(1:150,:,93,i),1),3); 
    fs=500;N=4096;n=0:N-1;t=n/fs;
    y=squeeze(data);
    Y=fft(y,N);
    A=abs(Y);f=n*fs/N;
    ph=2*angle(Y(1:N/2));
    ph=ph*180/pi;
    m(1,i,1) = ph(52);
    m(1,i,2) = ph(206);
    subplot(3,3,i)
    plot(f(1:N/2),ph(1:N/2));
    xlabel('频率/hz'),ylabel('相角'),title('相位谱');
    xlim([0 10]);
    grid on;
end

fs = 500;
N = 2048;
n=0:N-1;
f=n*fs/N;
for i = 1:9
    for coil = 1:96
        Y1 = fft(squeeze(mean(all_orient_data_EC(1:150,:,coil,i),1)),N);
        Y2 = fft(squeeze(mean(all_orient_data_SC(1:60,:,coil,i),1)),N);
        Y3 = fft(squeeze(mean(all_orient_data_ns(1:60,:,coil,i),1)),N);
        ph1=2*angle(Y1(1:N/2));
        ph2=2*angle(Y2(1:N/2));
        ph3=2*angle(Y3(1:N/2));
        m(1,i,coil,1) = ph1(52);
        m(1,i,coil,2) = ph1(206);
        m(2,i,coil,1) = ph2(52);
        m(2,i,coil,2) = ph2(206);
        m(3,i,coil,1) = ph3(52);
        m(3,i,coil,2) = ph3(206);
    end
end
m=m*180/pi;
idx1 = m>360;
idx2 = m<-360;
idx3 = m<0;
m(idx1) = m(idx1)-360;
m(idx2) = m(idx2)+360;
m(idx3) = m(idx3)+360;


subplot(3,2,1)
imagesc(squeeze(m(1,:,:,1)));
title('EC6.25hz-phase')
subplot(3,2,2)
imagesc(squeeze(m(1,:,:,2)));
title('EC25hz-phase')
subplot(3,2,3)
imagesc(squeeze(m(2,:,:,1)))
title('SC6.25hz-phase')
subplot(3,2,4)
imagesc(squeeze(m(2,:,:,2)))
title('SC25hz-phase')
subplot(3,2,5)
imagesc(squeeze(m(3,:,:,1)))
title('SSC6.25hz-phase')
subplot(3,2,6)
imagesc(squeeze(m(3,:,:,2)))
title('SSC25hz-phase')

sc_ec_1 = m(2,:,:,1)-m(1,:,:,1);
plot()





figure(1)
plot(m(1,:,1)-m(2,:,1))
hold on
plot(m(1,:,1));
plot(m(2,:,1));
plot(m(3,:,1));
legend('sc-ec', 'ec','sc','newSC')
hold off

figure(2)
plot(m(1,:,2)-m(2,:,2))
hold on
plot(m(1,:,2));
plot(m(2,:,2));
plot(m(3,:,2));
legend('sc-ec', 'ec','sc','newSC')
hold off
%EC的相位更大一点,相较于SC和newSC
%
figure(3)
x= 0:0.1:10;
plot(sin(x))
hold on 
plot(sin(x+2*pi))
plot(sin(2*x));
plot(sin(2*x+2*pi))
hold off
figure(4)
plot(sin(x+347/360*2*pi))
hold on
plot(sin(x-296/360*2*pi))
plot(sin(x-296/360*2*pi+4*pi))


%% Eg 1 单频正弦信号
ts = 0.01;
t = 0:ts:1;
A = 1.5;       % 幅值  
f = 2;         % 频率
w = 2*pi*f;    % 角频率
phi = pi/2;    % 初始相位 
x = A*sin(w*t+phi);   % 时域信号
figure
plot(t,x)
xlabel('时间/s')
ylabel('时域信号x(t)')
% DFT变换将时域转换到频域,并绘制频谱图
[f,X_m,X_phi] = fft(x,ts);
