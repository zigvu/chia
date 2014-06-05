%% Apply trained model to logo detection in images
clear all; clear; close all; clc;

%% Inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The directory containing the test images (The Results will be in a
% directory called 'Results' in the ImagesDir
ImagesDir = 'C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\TestMLS';
% The directory containing the Model
ModelDir = fullfile(pwd,'Models');
% Name of the Model (assigned during "Logo_Detection_Training") in the model directory 
ModelName = 'Adidas_Model_V1';  % Dont include (.mat)
ImgExt    = 'png';    % Extension of image files
% Each image is resized and run with the sliding window. These are the scales
Scales = [0.2:0.05:0.8 0.9:0.1:1.6];
Scales = 0.2:0.2:1.6;
% This is the step size for the sliding window. The actual width and height
% of the sliding window is stored in the model (for e.g. 32 x 32)
X_Step = 10; Y_Step = 10;     

% Directory to output all positive patches (So that any false positives can
% be fed back to model training)
OutputPositivePatches   = 1;    % If set to '1' , all 32x32 patches will be output to the directory
PositivePatchesDir = 'C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\LogoProcessing\3_Slants\PositivePatches';

% MultiCore: Keep 1 if data wont fit in memory. Max 4.
% The main issue is memory. As the training data gets larger, you require
% more memory to use more cores. My rule of thumb is that if data is less
% than 100K, use 4, 100 K to 300K I use around 2 and then 1 for anything
% larger.
CoresToUse = 1;    

% Threshold for positive detection
Thresh = 0.05;  % If the SVM output is bigger than 0.05, 
% End Inputs (Code Below) ***************************************************

%% Start Processing below
ImgDir = ImagesDir;

% Load results of KMeans / SVM Training
Detect = load(fullfile(ModelDir,[ModelName '.mat']));
Ht = Detect.CIFAR_DIM(1);
Wt = Detect.CIFAR_DIM(2);
or = Y_Step;
oc = X_Step;

% Start processor pool if needed
if CoresToUse > 1
    try
        matlabpool close    % Close any existing pool cores
    catch e
    end
    matlabpool(CoresToUse);
end

% Create directory to hold output images
OutDirName = 'DetectionResults';   % Name of the directory saving chunked images
if isdir(fullfile(ImgDir,OutDirName))
    delete(fullfile(ImgDir,OutDirName,['*.' ImgExt]))
else
    mkdir(fullfile(ImgDir,OutDirName))
end
ImageOutputDir = fullfile(ImgDir,OutDirName);

% Iterate through the images
D  = dir(fullfile(ImgDir,['*.' ImgExt]));

for d = 1:length(D)
    tic;    % Timing
    % Read image
    img = imread(fullfile(ImgDir,D(d).name));
    imgC = img;
    %Convert to gray scale if needed
    if length(size(img)) > 2, img = (rgb2gray(img)); end;
    % Mask to hold all the positive detection
    imgMask = zeros(size(imgC),'uint8');

    Clrs = jet(length(Scales));
%     Clrs = {'r','g','w'};
    LSt = {'-',':','-'};
    % Iterate through the scales
    for s = 1:length(Scales)
        Scale  = Scales(s);
        imScaled = imresize(img,Scale);
        
        % Iterate through the image and prepare
        PosX = zeros(1000e3,2);   % X Y
        testX = zeros(1000e3,Ht*Wt,'single');
        ScaleX = zeros(1000e3,1);
        k = 1;
        [rows,cols] = size(imScaled);
        % Extract Image Patches
        for rr = 1:or:rows-Ht+1
            for cc = 1:oc:cols-Wt+1
                PosX(k,:) = [cc rr];
                Block   = imScaled(rr:rr+Ht-1,cc:cc+Wt-1);
                testX(k,:) = reshape(Block,1,Ht*Wt);
                ScaleX(k) = Scale;
                k = k+1;
                %rectangle('position',[cc rr Ht Wt]./Scale,'edgecolor',Clrs(s,:));
                %rectangle('position',[cc rr Ht Wt]./Scale,'edgecolor',Clrs{s},'linewidth',1,'linestyle',LSt{s});
            end
        end
        PosX = PosX(1:k-1,:);
        testX = testX(1:k-1,:);

        % Run the detector
        % Extract features
        if CoresToUse > 1   % Use Multicore
            % Call the nonparallel version
            testXC = extract_features_parallel(testX, Detect.centroids, ...
                Detect.rfSize, Detect.CIFAR_DIM, Detect.M,Detect.P);            
        else
            testXC = extract_features_digits(testX,Detect.centroids, ...
            Detect.rfSize, Detect.CIFAR_DIM, Detect.M,Detect.P);
        end
        testXCs = bsxfun(@rdivide, bsxfun(@minus, testXC, Detect.trainXC_mean), Detect.trainXC_sd);
        testXCs = [testXCs, ones(size(testXCs,1),1)];
        % Apply SVM
        [val,labels] = max(testXCs*Detect.theta, [], 2);

        labels(val < Thresh) = 2;
        
        % Visualize results
        
        for k = 1:size(testX,1)
            if labels(k) == 1
                RStart  = max([1,round(PosX(k,2)./ScaleX(k)) + 1]);
                REnd    = min([RStart + round(Ht./ScaleX(k)), size(imgMask,1)]);
                CStart  = max([1, round(PosX(k,1)./ScaleX(k)) + 1]);
                CEnd    = min([size(imgMask,2), CStart + round(Wt./ScaleX(k))]);
                imgMask(RStart:REnd,CStart:CEnd,:) = imgMask(RStart:REnd,CStart:CEnd,:) + 1;
                % Save the positive patches
                if OutputPositivePatches == 1
                    Block = imresize(imgC(RStart:REnd,CStart:CEnd,:),[32 32]);
                    NameOfImgFile = ['Img_' num2str(d) '_Scale_' num2str(Scale) '_Patch_' num2str(k) '.png'];
                    imwrite(Block,fullfile(PositivePatchesDir,NameOfImgFile),'png');
                end
            end
        end

        fprintf('Image %i , Scale : %.2f , Time: %.2f \n',d,Scale,toc);
    end     % Scale
    
    % Find all the positive image patches and show them as transparency
    % overlay
    Alpha = 0.6;    
    imgMask = sign(imgMask);
    ForeIntensity = 150; %./max([1, max(imgMask(:))]);
    % Blend mask
    imBlend = (sign(imgMask)*ForeIntensity)*Alpha +  ...
                    (1-Alpha).*imgC;
    % Write to file
    imwrite(imBlend,fullfile(ImageOutputDir,D(d).name),ImgExt);
    
%     figure;
%         imshow(imBlend);
%         pause(0.1); drawnow;
        
    fprintf('** Image %i done ** \n',d);
end

% Close processor pool if needed
if CoresToUse > 1
    try
        matlabpool close    % Close any existing pool cores
    catch e
    end
end

