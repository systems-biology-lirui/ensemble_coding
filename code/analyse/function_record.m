%% 用于记录一些有用的函数

%% 调试函数

%错误直接断点
dbstop if error
%在断点处可以进行右键条件断点

%% 格式处理函数

% deal：用于将一个或者多个值分配给多个变量
[tmin,tmax] = deal(tmax,tmin);

% 快速的构建struct
a = struct('l', [1, 2, 3], 'k', struct('l', [2, 3]));

% isnumeric：用于检测是否是数值类型；isscalar：是否是标量
validFcn = @(x) assert(isnumeric(x)&&isscalar(x),errorMsg);

% eval:将字符串用做运行表达式，可以用于json文件的处理
x = 1;
str = 'y = x + 1';
eval(str);

%% 函数构建常用函数

% global：设置全局变量
% global g;这里注释化是为了防止对别的脚本发生影响
% g = 5;

%parsevarargin：解析参数，会得出逻辑值
arg = parsevarargin(varargin);

% 构建一个匿名函数
func = @(x,y) sum(x,y);

% 定义一个无输入参数的匿名函数
noop = @() disp('Hello, World!');

% validatestring:检测输入参数是否是一个被包含的字符串
lagOptions = {'multi','single'};
validFcn = @(x) any(validatestring(x,lagOptions));

% assert:如果第一个参数是真则继续执行，如果不为真，就显示第二个参数并停止执行。
% 这里相当于先验证是否x是1或者2
validFcn = @(x) assert(x==1 || x==2, errorMsg);

% addParameter：添加参数到解析器
addParameter(p,'type','multi',validFcn);



%% 运算函数

% 1.简单运算

% 取整数,floor取下，ceil取上
floor(3.7)
ceil(3.2)


% 2.复杂运算函数

% 最小二乘法计算协方差
[Cxx,Cxy] = olscovmat(x,y,lags,arg.type,arg.zeropad,arg.verbose);

%% 并发计算
tic
n = 200;
A = 500;
a = zeros(n);
parfor i = 1:n
    a(i) = max(abs(eig(rand(A))))
end
toc

%% 用于记录一些条件语句

% nargin:输入参数的数量
if nargin < 2 || isempty(dim)
    dim = 1;
end

% nargout：输出参数的数量
if nargout > 1
    rows = zeros(ncells,1);
end

% isnan：是nan值；error
if any(isnan(x{i}(:)))
    error('Input data contains NaN values.')
end

%条件的选择，可以加入otherwise
switch arg.type
    case 'multi'
        nvar = xvar*nlag+1;
    case 'single'
        nvar = xvar+1;
end

%对于输入参数是0，1的利用，如果为true，才会进行
if ~arg.zeropad
    y = truncate(y,tmin,tmax,yobs);
end

%使用逻辑值而不是for循环的运算
source = randi([50,100],5,3);
idx = find(sum(source<60,2));

%只有所有元素都是非零才会为1
if [1,2;0,1]
    res = 1;
else
    res = 10;
end

%斐波那契数列,从这里看while函数的作用，即不知道需要循环多久
%新的一点，就是disp怎么同时展示两个字符串
n = 2;
while f(n)<99999
    n = n+1;
    f(n) = f(n-1)+f(n-1);
    disp(num2str(n) + "," + num2str(f(n)));
end