clc;clear all;close all;
%% Inputs

InputDir    = 'C:\Users\Amit\Dropbox\EvanVideo\LogoDetection\BasicFrameWork\DiversifyPatches\InputImages';
ImageExtension = 'png';
OutputDir   = 'C:\Users\Amit\Dropbox\EvanVideo\LogoDetection\BasicFrameWork\DiversifyPatches\OutputImages';   %Any existing files will be deleted


NumberOfThreads = 2;
CompressionRatio    = 0.25;     % Extract 25 % of the unique patches  
InputPatchSize      = [64 64]; % [Width, Height]

% Extra Inputs (No need to modify unless necessary)
numClusters = 200 ;

% -- End Inputs ---------------------------------------------------------


%% Add VLFeat library to the path
% Path to VLFeat
VLFeatRoot = fullfile(pwd,'vlfeat-0.9.18');
run([VLFeatRoot '/toolbox/vl_setup']);
vl_version('verbose')    % Check if VLFeat is working
    
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


%% Write output to Directory

% Create output directory if needed
if isdir(OutputDir)
    delete(fullfile(OutputDir,['*.' ImageExtension]))
else
    mkdir(OutputDir)
end

% Directory to write to
OutDir = OutputDir;
% Number of patches to write
N = round(CompressionRatio * length(Imgs));;

k = 1;  % Tracker
OutStatus = zeros(size(trainX,1),1);    % Whether this image has allready been written
MaxIter = 500e3;
iter = 1;
tic;
while k < N & iter < MaxIter
    % Randomly choose a cluster
    cluster = randi(numClusters,[1,1]);
    % Find all images belonging to this cluster
    cidx = find(assignments == cluster);
    % Randomly choose an image from that cluster
    r = cidx(randi(length(cidx),[1 1]));
    % If this is image has not been written to directory before, write it
    if OutStatus(r) == 0
        % Copy the this image
        CopyFrom = fullfile(InputDir,Imgs(r).name);
        CopyTo  = fullfile(OutDir,Imgs(r).name);
        copyfile(CopyFrom,CopyTo);
%         Im = reshape(trainX(r,:),32,32);
%         imwrite(Im,fullfile(OutDir,['Patch_' num2str(k) '.png']),'png');
        OutStatus(r) = 1;
        if mod(k,100) == 0, fprintf('%i of %i written in %f s\n',k,N,toc); end
        k = k+1;
    end
    iter = iter+1;
end



