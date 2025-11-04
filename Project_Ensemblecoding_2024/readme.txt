2025.10.10-进行第一次重构
框架如下：

Project_Ensemblecoding_2024
│
├── 📂 code/               # 存放你编写的所有MATLAB代码
│   ├── 📂 +functions/     # 核心功能函数（MATLAB包）
│   ├── 📂 scripts/        # 按顺序执行的主流程脚本
│   └── 📂 config/         # 配置文件和参数
│
├── 📂 data/               # 存放所有数据
│   ├── 📂 raw/            # 原始数据 (只读!)
│   └── 📂 processed/      # 代码处理后生成的数据
│
├── 📂 toolboxes/          # 存放外部依赖的工具箱
│
├── 📂 results/            # 存放最终的输出结果
│   ├── 📂 figures/        # 生成的图片
│   └── 📂 tables/         # 生成的表格或统计结果
│
├── 📂 docs/               # 文档、笔记、实验方案等
│
├── 📜 .gitignore           # (如果使用Git) 告诉Git忽略哪些文件
├── 📜 README.md             # 项目说明文件
└── 📜 main_analysis.m      # (可选) 一键运行整个分析流程的主脚本