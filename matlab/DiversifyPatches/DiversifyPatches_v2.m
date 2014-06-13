clc;clear all;close all;

%% Inputs

InputDir    = '/home/ubuntu/logo/Input';
ImageExtension = 'png';
OutputDir   = '/home/ubuntu/logo/Output';   %Any existing files will be deleted
numClusters = 25 ; % Number of clusters to divid the images into
OutputCluster = 1;  % If set to yes. A directory will be created in the output dir 
                    % and populated with images from that cluster
ImagesPerCluster = 10;  % This many images will be extracted per cluster 
                    
NumberOfThreads = 1;
%CompressionRatio    = 0.25;     % Extract 25 % of the unique patches  
InputPatchSize      = [32 32]; % [Width, Height]


% -- End Inputs ---------------------------------------------------------


%% Add VLFeat library to the path
% Path to VLFeat
try
    
    VLFeatRoot = fullfile(pwd,'vlfeat-0.9.18');
    run([VLFeatRoot '/toolbox/vl_setup']);
    vl_version('verbose')    % Check if VLFeat is working
catch
    fprintf(['VL Feat not installed properly!\n Stopping execution ! \n']);
    return
end
%% Read Input Images

Imgs = dir(fullfile(InputDir,['*.' ImageExtension]));

trainX = zeros(length(Imgs),prod(InputPatchSize),'uint8');
trainY = ones(length(Imgs),1,'uint8');  % All negatives (value 2)
tic;
% Get a list of images in the directory
fprintf('\nReading Input patches ... \n');
for i = 1:length(Imgs)
    imFile = fullfile(InputDir,Imgs(i).name);
    im = (imread(imFile));  % All ready black and white  
    % Convert to gray scale
    if length(size(im)) > 2, im = rgb2gray(im); end   % Convert to gray scale if needed
    im = imresize(im,[InputPatchSize(2), InputPatchSize(1)]);
    trainX(i,:) = reshape(im,1,prod(size(im)));
    if mod(i,1000)==0, fprintf('  %i of %i read in %f s \n',i,length(Imgs),toc); end
end
fprintf('Completed read of %i input patches \n',length(Imgs));

%% Perform KMeans

disp('Performing KMEANs ... expect 10 to 30 mins for large patches');
vl_threads(NumberOfThreads);

[centers, assignments] = vl_kmeans(single(trainX'), numClusters, 'verbose', 'distance', 'l2', 'algorithm', 'elkan'); 
% [centers, assignments] = vl_kmeans(single(trainX'), numClusters, 'verbose', 'distance', 'l2' ...
%     , 'MaxNumIterations',250,'Algorithm', 'ANN', 'MaxNumComparisons', ceil(numClusters / 10)); 

disp('KMeans done');

%% Create output directory if needed
if isdir(OutputDir)
    rmdir(OutputDir,'s');
    mkdir(OutputDir)
    %delete(fullfile(OutputDir,['*.' ImageExtension]))
else
    mkdir(OutputDir)
end

%% Write clusters
disp('Sending images to their respective cluster directory in outputdir');

for c = 1:numClusters
    % Create a directory for the cluster
    ClusterDir = fullfile(OutputDir,num2str(c));
    if isdir(ClusterDir)
        delete(fullfile(ClusterDir,['*.' ImageExtension]))
    else
        mkdir(ClusterDir)
    end
    
    % Move files from input directory to cluster directory
    cidx = find(assignments == c);  % All files belonging to this cluster
    for k = 1:length(cidx);
        % Copy the this image
        r = cidx(k);
        CopyFrom = fullfile(InputDir,Imgs(r).name);
        CopyTo  = fullfile(ClusterDir,Imgs(r).name);
        copyfile(CopyFrom,CopyTo);
    end

    % Find the top (X) images clostest to the cluster center and send them
    % to the output folder
    %a. Build a KDTree for fast lookup    
    ClusterX = single((trainX(cidx,:))');
    kdtree = vl_kdtreebuild(ClusterX) ;
    %b. Find the closest (X) points that are closest to the center
    [index, distance] = vl_kdtreequery(kdtree, ClusterX, centers(:,c), 'NumNeighbors', ImagesPerCluster) ;
    %c. Identify that nearest images in the overall images index
        % If the cluster has less than expected images per cluster
    NonEmpty = find(index == 0);
    if length(NonEmpty) > 0
        index = index(index > 0);  % Remove empty entries
        fprintf('  ** Cluster %i has less than the minimum %i images per cluster!!\n',c,ImagesPerCluster);
    end
    imgindex = cidx(index);
    %d. copy images to output folder
    for ii = 1:length(imgindex);
        r = imgindex(ii);
        CopyFrom = fullfile(InputDir,Imgs(r).name);
        CopyTo  = fullfile(OutputDir,Imgs(r).name);
        copyfile(CopyFrom,CopyTo);
    end
    fprintf('Cluster %i done! \n',c)
    
end
%% Write output to Directory
% 
% % Create output directory if needed
% if isdir(OutputDir)
%     delete(fullfile(OutputDir,['*.' ImageExtension]))
% else
%     mkdir(OutputDir)
% end
% 
% % Directory to write to
% OutDir = OutputDir;
% % Number of patches to write
% N = round(CompressionRatio * length(Imgs));;
% 
% k = 1;  % Tracker
% OutStatus = zeros(size(trainX,1),1);    % Whether this image has allready been written
% MaxIter = 500e3;
% iter = 1;
% tic;
% while k < N & iter < MaxIter
%     % Randomly choose a cluster
%     cluster = randi(numClusters,[1,1]);
%     % Find all images belonging to this cluster
%     cidx = find(assignments == cluster);
%     % Randomly choose an image from that cluster
%     r = cidx(randi(length(cidx),[1 1]));
%     % If this is image has not been written to directory before, write it
%     if OutStatus(r) == 0
%         % Copy the this image
%         CopyFrom = fullfile(InputDir,Imgs(r).name);
%         CopyTo  = fullfile(OutDir,Imgs(r).name);
%         copyfile(CopyFrom,CopyTo);
% %         Im = reshape(trainX(r,:),32,32);
% %         imwrite(Im,fullfile(OutDir,['Patch_' num2str(k) '.png']),'png');
%         OutStatus(r) = 1;
%         if mod(k,100) == 0, fprintf('%i of %i written in %f s\n',k,N,toc); end
%         k = k+1;
%     end
%     iter = iter+1;
% end



