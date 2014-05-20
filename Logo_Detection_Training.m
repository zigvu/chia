%% This script is for training models for logo detection
clear all; clear; close all; clc;

%% Inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Directory containing positives and negatives examples

% The directory containing the synthetically generated patches of logo images
PositivePatchesDir = 'C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\LogoProcessing\SyntheticLogos';
PositivePatchesDir = 'C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\SyntheticThreeSlants2';
% The directory containing the negative patches (for e.g. any 32 x 32 pixel patch)
NegativePatchesDir = 'C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\LogoProcessing\NegativePatches';
% The directory conatining img bank frames that will be sampled randomly to
% extract patches for negative image training
NegImgBankDir       = 'C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\LogoProcessing\NegativeImgBank';
PatchesToExtract    = 200e3;   % Number of patches to extract from Negative Image Bank
ImagePatchSize      = [32 32];  % Image Patch Size to expect
ImgExt              = 'png';    % Extension of image files
TestPercent         = [0.2];     % Keep 20% of data for testing (the remaining will be used for training)

% Model Params
ModelDir    = fullfile(pwd,'Models');   
ModelName   = 'Adidas_3Slants_V1';    % Give the model a name
numCentroids = 150;    % Number of codebook variables (bigger the more data you need and more representational capacity)
% MultiCore: Keep 1 if data wont fit in memory. Max 4.
% The main issue is memory. As the training data gets larger, you require
% more memory to use more cores. My rule of thumb is that if data is less
% than 100K, use 4, 100 K to 300K I use around 2 and then 1 for anything
% larger.
NumberOfCores = 1;      

    % The following model parameters do not need changing (atleast often)
numPatches  = 400000;
rfSize      = 8;
whitening   = true;     
CIFAR_DIM   = ImagePatchSize;

% End Inputs (Code Below) ***************************************************

%% Read Data  From Images in preparation for training
fprintf('\n** Reading images for model training **\n');
Read_Data_ForModelTraining;     % The portion that reads the data from file is in this script
% Convert the data to 'single' (from uint8)
trainX = single(trainX);
trainY = single(trainY);
fprintf('\n** Data read complete **\n');
[n,x] = hist(trainY,1:2);
%disp(['Data Set balance (pos to neg): ' num2str(n(1)/sum(n)*100) ' % : ' num2str(n(2)/sum(n)*100) '%']);
fprintf('\n Ratio of positive to negative samples is %f ( %i pos / %i neg ) \n',n(1)/n(2)*100,n(1),n(2));
%% ************************************************************************* 
% K Means Code Book learning
%************************************************************************* 

fprintf('\n****************************************************************\n')
fprintf('**KMeans Code Book Learning*************************************\n')
fprintf('\n Patch Generation \n');
% Extract Patches
patches = zeros(numPatches, rfSize*rfSize);
for i=1:numPatches
  if (mod(i,10000) == 0) fprintf('Extracting patch: %d / %d\n', i, numPatches); end
  
  r = random('unid', CIFAR_DIM(1) - rfSize + 1);
  c = random('unid', CIFAR_DIM(2) - rfSize + 1);
  patch = reshape(trainX(mod(i-1,size(trainX,1))+1, :), CIFAR_DIM);

  patch = patch(r:r+rfSize-1,c:c+rfSize-1,:);
  patches(i,:) = patch(:)';
end

% Run K-means on patches for codebook generation
fprintf('\n## Running KMeans ## \n');
patches = bsxfun(@rdivide, bsxfun(@minus, patches, mean(patches,2)), sqrt(var(patches,[],2)+10));
% whiten
C = cov(patches);
M = mean(patches);
[V,D] = eig(C);
P = V * diag(sqrt(1./(diag(D) + 0.1))) * V';
patches = bsxfun(@minus, patches, M) * P;
centroids = run_kmeans(patches, numCentroids, 50);
% show_centroids(centroids, rfSize); drawnow;
clear patches   % Save memory
% Run whitening



%% ************************************************************************* 
% SVM training 
%************************************************************************* 
fprintf('\n****************************************************************\n')
fprintf('**SVM Training ************************************************\n')
fprintf('\n Feature Generation \n');
% Feature generation: Start multiprocessing and then feature generation
CoresToUse  = min([NumberOfCores, 4]);  % No more than 4 cores
if CoresToUse > 1
    try
        matlabpool close    % Close any existing pool cores
    catch e
    end
    matlabpool(CoresToUse);
    trainXC = extract_features_parallel(trainX, centroids, rfSize, CIFAR_DIM, M,P);    
else
    % Call the nonparallel version
    trainXC = extract_features_digits(trainX, centroids, rfSize, CIFAR_DIM, M,P);
end
addpath minFunc;
% Take trainX back to integer to save memory
trainX = uint8(trainX);

%% Standardize data
trainXC_mean = mean(trainXC);
trainXC_sd = sqrt(var(trainXC)+0.01);
% edit done
trainXCs = bsxfun(@rdivide, bsxfun(@minus, trainXC, trainXC_mean), trainXC_sd);
trainXCs = [trainXCs, ones(size(trainXCs,1),1)];

% train classifier using SVM
C = 100;
theta = train_svm(trainXCs, trainY, C);

% Save results on 'Model' file
save(fullfile(ModelDir,ModelName),'CIFAR_DIM','M','P','centroids','rfSize','theta','trainXC_mean','trainXC_sd');
%save Model_Digits_Detect CIFAR_DIM M P centroids rfSize theta trainXC_mean trainXC_sd

%% Evaluate on test and training data and show results
% Test Accuracy on test data (not used in training )

fprintf('\n****************************************************************\n')
fprintf('**Evaluation on Test and Training Data****************************\n')
fprintf('\n Feature Generation on test data \n');
% Prepare testX data
testX = single(testX);
testY = single(testY);
testY(testY ==0) = 2;   % For the SVM

% compute testing features and standardize
if CoresToUse > 1   % Use Multicore
    % Call the nonparallel version
    testXC = extract_features_parallel(testX, centroids, rfSize, CIFAR_DIM, M,P);
    matlabpool close;   % Close the pool afterwards    
else
    testXC = extract_features_digits(testX,centroids, rfSize, CIFAR_DIM, M,P);
end
testXCs = bsxfun(@rdivide, bsxfun(@minus, testXC, trainXC_mean), trainXC_sd);
testXCs = [testXCs, ones(size(testXCs,1),1)];

% Evaluate on Training Results
disp('**Training Results *******************************************');
[val,labels] = max(trainXCs*theta, [], 2);
fprintf('Training accuracy %2.1f%%\n', 100 * (1 - sum(labels ~= trainY) / length(trainY)))
fprintf('Recall: %2.2f%%\n', 100 * (sum(labels ==1 & trainY == 1)/sum(trainY == 1)));
fprintf('Precision: %2.2f%%\n', 100 * (sum(labels ==1 & trainY == 1)/sum(labels == 1)));
disp('*********************************************');

% test and print result
[~,labelsT] = max(testXCs*theta, [], 2);
disp('**Results on Test data (not used for training) *******************');
fprintf('Test accuracy %f%%\n', 100 * (1 - sum(labelsT ~= testY) / length(testY)));
fprintf('Recall: %2.2f%%\n', 100 * (sum(labelsT ==1 & testY == 1)/sum(testY == 1)));
fprintf('Precision: %2.2f%%\n', 100 * (sum(labelsT ==1 & testY == 1)/sum(labelsT == 1)));
% fprintf('True Positives %2.2f%%\n', 100 * (sum(labelsT ==1 & testY == 1) / sum(labelsT==1)));
% fprintf('False Positives %2.2f%%\n', 100 * (sum(labelsT ==1 & testY == 2) / sum(labelsT==1)));
% fprintf('True Negatives %2.2f%%\n', 100 * (sum(labelsT ==2 & testY == 2) / sum(labelsT==2)));
% fprintf('False Negatives %2.2f%%\n', 100 * (sum(labelsT ==2 & testY == 1) / sum(labelsT==1)));
disp('*********************************************');


