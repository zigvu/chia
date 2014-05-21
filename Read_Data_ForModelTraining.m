%% Read image data for logo model training
clear X_Train Y_Train X_Test Y_Test  % Temporary variables
%% 1. Read positive Patches Examples

Imgs = dir(fullfile(PositivePatchesDir,['*.' ImgExt]));

trainX = zeros(length(Imgs),prod(ImagePatchSize),'uint8');
trainY = ones(length(Imgs),1,'uint8');  % All positives
tic;
% Get a list of images in the directory
fprintf('\nReading positive image samples ... \n');
for i = 1:length(Imgs)
    imFile = fullfile(PositivePatchesDir,Imgs(i).name);
    im = (imread(imFile));  % All ready black and white  
    %im = imresize(im,[32, 32]);
    if length(size(im)) > 2, im = rgb2gray(im); end   % Convert to gray scale if needed
    trainX(i,:) = reshape(im,1,prod(ImagePatchSize));
    if mod(i,1000)==0, fprintf('  %i of %i in %f s \n',i,length(Imgs),toc); end
end
fprintf('%i positive samples read \n',length(Imgs));

% Divide into train and test
r = rand(size(trainX,1),1);
testidx = find(r <= TestPercent );  % 80/20 split for train / test
trainidx = find(r > TestPercent );
testX = trainX(testidx,:); testY = trainY(testidx,:);
trainX = trainX(trainidx,:);trainY = trainY(trainidx,:);

% Save data (later concatenate negative data)
X_Train = trainX; Y_Train = trainY;
X_Test = testX; Y_Test = testY;
% clear remaining data
clear train* test* *idx r
clear D Imgs b d i im* map 


%% 2. Read Negative PatchesExamples

Imgs = dir(fullfile(NegativePatchesDir,['*.' ImgExt]));

trainX = zeros(length(Imgs),prod(ImagePatchSize),'uint8');
trainY = 1+ones(length(Imgs),1,'uint8');  % All negatives (value 2)
tic;
% Get a list of images in the directory
fprintf('\nReading Negative patches ... \n');
for i = 1:length(Imgs)
    imFile = fullfile(NegativePatchesDir,Imgs(i).name);
    im = (imread(imFile));  % All ready black and white  
    if length(size(im)) > 2, im = rgb2gray(im); end   % Convert to gray scale if needed
    trainX(i,:) = reshape(im,1,prod(ImagePatchSize));
    if mod(i,1000)==0, fprintf('  %i of %i in %f s \n',i,length(Imgs),toc); end
end
fprintf('%i Negative patches read \n',length(Imgs));

% Divide into train and test
r = rand(size(trainX,1),1);
testidx = find(r <= TestPercent );  % 80/20 split for train / test
trainidx = find(r > TestPercent );
testX = trainX(testidx,:); testY = trainY(testidx,:);
trainX = trainX(trainidx,:);trainY = trainY(trainidx,:);

% Save data (later concatenate negative data)
X_Train = [X_Train;trainX]; Y_Train = [Y_Train;trainY];
X_Test = [X_Test;testX]; Y_Test = [Y_Test;testY;];

% clear remaining data
clear train* test* *idx r
clear D Imgs b d i im* map 

%% 3. Read patches from Negative Image Bank

ImgDir = NegImgBankDir;
Ht = ImagePatchSize(1); Wt = ImagePatchSize(2);
Samples = PatchesToExtract; % We want roughly 500K sample patches
D = dir(ImgDir);
TotalImages = length(D)-2;
PatchesPerImage = round(Samples./TotalImages);
trainX = zeros(PatchesPerImage*TotalImages,Ht*Wt,'uint8');
trainY = 1+ones(PatchesPerImage*TotalImages,1,'uint8');  % All negative examples
k = 1;
fprintf('\n Reading patches from negative image bank ... \n');
for d = 1:length(D)
    ImgName = D(d).name;
    if ImgName(1) == '.', continue; end  % Dont go forward if the file is '.' or '..'
    
    im = (imread(fullfile(ImgDir,ImgName)));
    if length(size(im)) > 2, im = rgb2gray(im); end;
    
    % Generate random patches
    rows = randi(size(im,1)-Ht,PatchesPerImage,1);
    cols = randi(size(im,2)-Wt,PatchesPerImage,1);
    for s = 1:PatchesPerImage
        trainX(k,:) = reshape(im(rows(s)+1:rows(s)+Ht,cols(s)+1:cols(s)+Wt),1,Ht*Wt);
        %imwrite(im(rows(s)+1:rows(s)+Ht,cols(s)+1:cols(s)+Wt),fullfile('C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\LogoProcessing\NegativePatches\FromImgBank',['Img_' num2str(k) '.png']),'png');
        k = k+1;
    end
    
    if mod(d-1,50) == 0, disp(['Patches extracted from ' num2str(d-2) ' of ' num2str(TotalImages) ' images']); end
end
fprintf('%i Negative patches read from %i images (%i patches per image)\n',PatchesToExtract,TotalImages,PatchesPerImage);

% Divide into train and test
r = rand(size(trainX,1),1);
testidx = find(r <= TestPercent );  % 80/20 split for train / test
trainidx = find(r > TestPercent );
testX = trainX(testidx,:); testY = trainY(testidx,:);
trainX = trainX(trainidx,:);trainY = trainY(trainidx,:);

% Save data (later concatenate negative data)
X_Train = [X_Train;trainX]; Y_Train = [Y_Train;trainY];
X_Test = [X_Test;testX]; Y_Test = [Y_Test;testY;];

clear train* test* *idx r 
clear ImgDir Ht Wt D Samples TotalImages PatchesPerImage k rows cols s ImgName ans d im

%% Save Data for model training (because most of the script uses trainX as the naming convention instead of X_Train)

trainX = X_Train; clear X_Train
trainY = Y_Train; clear Y_Train
testX = X_Test; clear X_Test
testY = Y_Test; clear Y_Test;