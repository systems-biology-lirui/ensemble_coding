频谱结果，不同关注频率下的d-prime结果，每个通道进行独立计算，并将通道作为样本进行显著性比较。

采用不同的计算方式：
session_mean: 在session内进行trial平均之后，session之间进行频谱结果的平均。
session_mean_coil: 采用某些数量的通道来满足某种条件（比如SG25hz不显著）。
session_nonmean: 所有trial先进行频谱之后在进行平均。

*d-prime是用target与random对比得到，表示6.25hz的明显程度。