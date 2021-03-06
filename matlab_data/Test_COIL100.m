fprintf('****************************************\n')
fprintf('Test on COIL100\n')
fprintf('****************************************\n')

diary('result_COIL100.txt');
diary on;

%% load data
filename = {'tiny_imagenet_xce'};
%filename = {'UKBench_4096_xce'};
load ( strcat(filename{1},'.mat')); fea = double(fea);
nClass = length(unique(gnd));
% Normalization
Norms = sqrt(sum(fea.^2,2));
fea =  bsxfun(@times, fea, 1./Norms);

%% Expermential setting
new_data = 1; plot_figure = 1; 
% kmeans setting
run_1star = 0; run_kind = 1; correction = 1;
run_SR = 1; No_SR = 10; run_joint = 0; run_R = 0;
run_kmeans = 1; No_kmeans = 10;  Phase_kmeans = 'on';
run_kmedoids = 0; No_kmedoids = 20;  Phase_kmedoids = 'on';
run_kmedians = 0; No_kmedians = 20;  Phase_kmedians = 'on';

fprintf('run_1star: %i, run_kind: %i correction: %i\n',...
    run_1star,run_kind,correction)
fprintf('run_kmeans: %i, No_kmeans: %i, Phase_kmeans: %s\n',...
    run_kmeans, No_kmeans, Phase_kmeans)
fprintf('run_kmedoids: %i, No_kmedoids: %i, Phase_kmedoids: %s\n',...
    run_kmedoids, No_kmedoids, Phase_kmedoids)

% data setting
K_cluster = round(linspace(20,nClass,10)); ntest =  numel(K_cluster);

% Similarity matrix setting
Metric = 'Euclidean'; NeighborMode = 'KNN';
knn = 5; WeightMode = 'HeatKernel'; parameter = 1;

%% Start test
T = []; FI =[]; FM =[]; AC = []; NMI = []; IDX = {}; PUR = [];
for j = 1:ntest
    k = K_cluster(j);             % k is the number of classes.
    dataId = []; idxg = [];
    ind = (1:nClass);
    for i = 1:k
        id = find(gnd ==ind(i))';
        dataId =[dataId id]; %#ok<*AGROW>
        idxg = [idxg; i*ones(length(id),1)];
    end
    M = double(fea(dataId,:)); [n,d] = size(M);
    
    fprintf('\n[n,d,k] = [%i,%i,%i]\n',n,d,k)
    
    if new_data == 1
        %% Similarity Matrix generation
        options = [];
        options.Metric = Metric; options.NeighborMode = NeighborMode;
        options.k = knn; options.WeightMode = WeightMode;
        options.t = parameter; options.gnd = idxg;
        tic
        K = constructW(M,options); K = (K + K')/2;
%         X = M;
%         nsq=sum(X.^2,2);
%         K=bsxfun(@minus,nsq,(2*X)*X.');
%         K=bsxfun(@plus,nsq.',K);
%         sigma=2;
%         K=exp(-K/sigma^2);
        toc
        %% Eigenspace_generation        
        Type = 'Normalized Laplacian';
        tic
        U = Eigenspace_generation(K,k,Type);
        toc
    end
    %% main
    %%%%%%%%%%%%%%%%%%%%%%%
    Comparison_Centroid_KindAP;
    Ns = sort(out.N,2,'descend'); 
    s = 1 - Ns(:,2)./Ns(:,1);
    fprintf('Soft indicator: Mean(s) = %.2f \n',mean(s));
    %%%%%%%%%%%%%%%%%%%%%%%
    T  = [T; t]; FI = [FI; fi]; FM = [FM; fm];
    AC = [AC; ac]; NMI = [NMI; nmi]; PUR=[PUR; pur];
    % IND{j,rr} = ind(1:k);
end
%% Plot
if plot_figure == 1
    subplot(235)
    % figure
    h = plot(K_cluster,FI(:,4),'ro-',K_cluster,FI(:,5),'bd--',K_cluster,FI(:,8),'m+:',...,
        K_cluster,FI(:,3),'k.-');
    g = gca; set(g,'FontSize',12);
    xlim([K_cluster(1),K_cluster(end)])
    hh = legend('\color{red} KindAP','\color{blue} KindAP+L',...
        '\color{magenta} Lloyd(10 runs)','\color{black} SR(10 runs)','location','NorthWest');
    set(hh,'FontSize',10);
    xlabel('Number of Clusters k','FontSize',13)
    ylabel('K-ind Square Error','FontSize',13)
    set(h,'linewidth',2,'MarkerSize',8); grid on; drawnow, shg
    title('FI: COIL100 [n,d,k] = [72k,1024,k]','FontSize',13)
    
    subplot(234)
    % figure
    h = plot(K_cluster,FM(:,4),'ro-',K_cluster,FM(:,5),'bd--',K_cluster,FM(:,8),'m+:',...,
        K_cluster,FM(:,3),'k.-');
    g = gca; set(g,'FontSize',12);
    xlim([K_cluster(1),K_cluster(end)])
    hh = legend('\color{red} KindAP','\color{blue} KindAP+L',...
        '\color{magenta} Lloyd(10 runs)','\color{black} SR(10 runs)','location','NorthWest');
    set(hh,'FontSize',10);
    xlabel('Number of Clusters k','FontSize',13)
    ylabel('K-means Square Error','FontSize',13)
    set(h,'linewidth',2,'MarkerSize',8); grid on; drawnow, shg
    title('FM: COIL100 [n,d,k] = [72k,1024,k]','FontSize',13)
    
    subplot(231)
    h = plot(K_cluster,AC(:,4),'ro-',K_cluster,AC(:,5),'bd--',K_cluster,AC(:,8),'m+:',...,
        K_cluster,AC(:,3),'k.-');
    % set (gca,'position',[0.12,0.12,0.8,0.8] )
    g = gca; set(g,'FontSize',12);
    xlim([K_cluster(1),K_cluster(end)])
    hh = legend('\color{red} KindAP','\color{blue} KindAP+L',...
        '\color{magenta} Lloyd(10 runs)','\color{black} SR(10 runs)','location','NorthWest');
    set(hh,'FontSize',10);
    xlabel('Number of Clusters k','FontSize',13)
    ylabel('Accuracy (%)','FontSize',13)
    set(h,'linewidth',2,'MarkerSize',8); grid on; drawnow, shg
    title('AC: COIL100 [n,d,k] = [72k,1024,k]','FontSize',13)
    
    subplot(232)
    h = plot(K_cluster,NMI(:,4),'ro-',K_cluster,NMI(:,5),'bd--',K_cluster,NMI(:,8),'m+:',...,
        K_cluster,NMI(:,3),'k.-');
    % set (gca,'position',[0.12,0.12,0.8,0.8] )
    g = gca; set(g,'FontSize',12);
    xlim([K_cluster(1),K_cluster(end)])
    hh = legend('\color{red} KindAP','\color{blue} KindAP+L',...
        '\color{magenta} Lloyd(10 runs)','\color{black} SR(10 runs)','location','NorthWest');
    set(hh,'FontSize',10);
    xlabel('Number of Clusters k','FontSize',13)
    ylabel('NMI (%)','FontSize',13)
    set(h,'linewidth',2,'MarkerSize',8); grid on; drawnow, shg
    title('NMI: COIL100 [n,d,k] = [72k,1024,k]','FontSize',13)
    
    subplot(233)
    h = plot(K_cluster,T(:,4),'ro-',K_cluster,T(:,5),'bd--',K_cluster,T(:,8),'m+:',...,
        K_cluster,T(:,3),'k.-');
    g = gca; set(g,'FontSize',12);
    xlim([K_cluster(1),K_cluster(end)])
    hh = legend('\color{red} KindAP','\color{blue} KindAP+L',...
        '\color{magenta} Lloyd','\color{black} SR','location','NorthWest');
    set(hh,'FontSize',10);
    xlabel('Number of Clusters k','FontSize',13)
    ylabel('Time (s)','FontSize',13)
    set(h,'linewidth',2,'MarkerSize',8); grid on; drawnow, shg
    title('T: COIL100 [n,d,k] = [72k,1024,k]','FontSize',13)
end

%% Save
save result_COIL100.mat K_cluster T FM FI AC NMI PUR
save result_COIL100_all.mat