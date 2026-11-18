% import/paste data (row vectors of D coeffs)

% 4h data
WT_5 = [];
R_5 = [];
G_5 = [];
P_5 = [];

WT_1_4h = [0.182,0.214,0.176];
R_1_4h = [];
G_1_4h = [0.115,0.133,0.149,0.164,0.103];
P_1_4h = [0.196,0.182,0.223];

% 24 h data
WT_1_24h = [0.092,0.114,0.121,0.089];
R_1_24h = [];
G_1_24h = [0.061,0.052,0.068,0.098,0.056,0.078];
P_1_24h = [0.116,0.131,0.13,0.161,0.118,0.113];

%% 1 uM 4h
% set up
data = [WT_1_4h P_1_4h G_1_4h];
data_cell = {WT_1_4h, P_1_4h, G_1_4h};
labels = ["WT", "P525L", "G156E"];
grouping = [];

for i = 1:3
    for j = 1:length(data_cell{i})
        grouping = [grouping labels(i)];
    end
end

% plot
figure, boxplot(data, grouping)
hold on, scatter(ones(size(WT_1_4h)),WT_1_4h,'bo')
hold on, scatter(2*ones(size(P_1_4h)),P_1_4h,'bo')
hold on, scatter(3*ones(size(G_1_4h)),G_1_4h,'bo')
ylim([0 0.4])

ylabel('D (um^2/s)')
title('Partial FRAP 4h 5 uM FUS 1 uM RNA')

%% 1 uM 24h
% set up
data = [WT_1_24h P_1_24h G_1_24h];
data_cell = {WT_1_24h, P_1_24h, G_1_24h};
labels = ["WT", "P525L", "G156E"];
grouping = [];

for i = 1:3
    for j = 1:length(data_cell{i})
        grouping = [grouping labels(i)];
    end
end

% plot
figure, boxplot(data, grouping)
hold on, scatter(ones(size(WT_1_24h)),WT_1_24h,'bo')
hold on, scatter(2*ones(size(P_1_24h)),P_1_24h,'bo')
hold on, scatter(3*ones(size(G_1_24h)),G_1_24h,'bo')
ylim([0 0.4])

ylabel('D (um^2/s)')
title('Partial FRAP 24h 5 uM FUS 1 uM RNA')

%% 5 uM 4h
% set up
data = [WT_5 R_5 G_5];
data_cell = {WT_5, R_5, G_5};
labels = ["WT", "R", "G"];
grouping = [];

for i = 1:3
    for j = 1:length(data_cell{i})
        grouping = [grouping labels(i)];
    end
end

% plot
figure, boxplot(data, grouping)
hold on, scatter(ones(size(WT_5)),WT_5,'bo')
hold on, scatter(2*ones(size(R_5)),R_5,'bo')
hold on, scatter(3*ones(size(G_5)),G_5,'bo')
ylim([0 0.4])

ylabel('D (um^2/s)')
title('Partial FRAP 4h 5 uM FUS 5 uM RNA')
