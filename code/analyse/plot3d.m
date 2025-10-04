test_tar_ran =[];
for i = 1:14
    nn = num(i);
    for coil = 1:96
        test_tar_ran(:,:,coil,i) = mean(tar_ran.(sprintf('session%d',nn)).(sprintf('coil%d',coil)).target_ra,1);
    end
end
test_tar_ran_mean = mean(test_tar_ran,3);
figure(1);
for i = 1:14
    subplot(4,4,i);
    plot(F_ROI(50:450),test_tar_ran_mean(1,50:450,1,i));
    name = sprintf('session%d',((i*2)-1)*10);
    subtitle(name);
    xline([6.25,12.5,18.75],'red')
   
end
figure(2);
for i = 1:14
    subplot(4,4,i);
    plot(F_ROI(50:150),test_tar_ran_mean(1,50:150,1,i));
    name = sprintf('session%d',((i*2)-1)*10);
    subtitle(name);
    xline(6.25,'red')
end
figure(3);
plot(tar_ran_mean_mean(103,1:9));
xticklabels(10:20:170);


blank_test = [];
for i = 1:14
    nn = num(i);
    for coil = 1:96
        blank_test(:,:,coil,i) = mean(cluster_data.(sprintf('session%d',nn)).(sprintf('coil%d',coil)).blank(:,1:1640),1);
    end
end
blank_test_mean = squeeze(mean(blank_test,3));

c1 = [1,2,3;1,3,5;1,5,9];
mesh(c1(1,:),c1(2,:),c1(3,:))


%% tar-ran
[x,y] = meshgrid(1:96,F_ROI(50:450,:));
c1 = [];
for i =1:96
    c1(i,:)=mean(tar_ran_orient_data.ori1.(sprintf('coil%d',i))(:,50:450),1);
end

figure(1);
mesh(x, y, c1');
[x,y] = meshgrid(1:96,F_ROI(50:450,:));
mesh(x, y, c1');
figure(3);
meshc(x, y, c1');
yline(6.25,'red');
hold on; % 保持当前图形，以便在上面添加新的图形
plot3([0, 100], [6.25, 6.25], [-800, -800], 'r', 'LineWidth', 2);

%tar
c0 = [];
for i =1:96
    c0(i,:)=mean(tar_orient_data.ori17.(sprintf('coil%d',i))(:,50:450),1);
end
figure(1);
meshc(x, y, c0');
c1 = [];
for i =1:96
    c1(i,:)=mean(tar_ran_orient_data.ori17.(sprintf('coil%d',i))(:,50:450),1);
end
figure(2);
meshc(x, y, c1');

% 170好

c1 = [];
for i =1:96
    c1(i,:)=mean(tar_orient_data.ori1.(sprintf('coil%d',i))(:,50:450),1);
end
figure(1);
meshc(x, y, c1');



c2 = [];
for i =1:96
    c2(i,:)=mean(tar_blank_data.ori3.(sprintf('coil%d',i))(:,50:450),1);
end
figure(1);
meshc(x, y, c2');

c3 = [];
for i =1:96
    c3(i,:)=tar_ran.session3.(sprintf('coil%d',i)).ra_bl(:,50:450);
end
figure(2);
meshc(x, y, c3');


c3 = [];
for i =1:96
    c3(i,:)=mean(tar_ran.session3.(sprintf('coil%d',i)).random(:,50:450),1);
end
[x,y] = meshgrid(1:96,F_ROI(50:450,:));
figure(1);
meshc(x, y, filterdata_session3_mena(:,50:450)');


figure(2);
meshc(x, y, filterdata_session3_menar(:,50:450)');
figure(3);
meshc(x, y, filterdata_session3_menab(:,50:450)');
figure(4);
meshc(x, y, (filterdata_session3_mena(:,50:450)-filterdata_session3_menar(:,50:450))');


