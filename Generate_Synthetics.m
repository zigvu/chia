%% This script is for the generation of Synthetic logo images given different
% viewing angles, backgrounds, blurring etc.
clear all; clear; close all; clc;

%% Inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This is the base directory of all the images
BaseDir = 'C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\LogoProcessing\3_Slants';

% The directory containing the logo images 
LogoImgDir = 'C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\LogoProcessing\3_Slants\LogoImages';
% The directory containing the background images
BackImgDir = 'C:\Users\Amit\Documents\EvanVideo\LogoDataSets\Adidas\LogoProcessing\3_Slants\Background';

% Image extensions
ImgExt = 'png';     % Lets just keep it to png if we can

% Final patch size properties
FinalImgSize = [32 32]; % Size in pixels of final image

% Chunk the image into square patches
ChunkImage = 1;     % Only makes sense for very rectangular logos, it will be cut into square images

% Synthetic variation settings
Rotations   = -26:2:26;
GaussianBlurStd = [1 4 8];  % Gaussian Blurring Params ( Higher number means more blurring
MotionBlurLength = [1 8 10];% Motion Blurring Params (Higher Number mean more blurring)

% Additional settings (not too important), dont change if not needed
GHSize = [10 10];           % Kernel size for gaussian blur
GaussianNoise   = 0.01;     % Additive gaussian noise std.dev
BackGround_Transparency     = 0.0:0.05:0.2;

TestRun = 0;    % If this is '1', it only shows the extremes of the settings
                % Set to '0' for actual run

% End Inputs (Code Below) ***************************************************

% Ignore
% Azimuths    =   -25:5:25;   % Azimuth viewing angle (e.g., -25:5:25 means from -25 deg to 25 deg with step size of 5 deg
% Elevations  =   60:8:90;    % Viewing elevations (degrees)

%% Run chunking (i.e. divide larger logo into square chunks) if the user has requested
% Create directory for saving chunked images
ChunkDirName = 'ChunkedImgs';   % Name of the directory saving chunked images
if isdir(fullfile(BaseDir,ChunkDirName))
    delete(fullfile(BaseDir,ChunkDirName,['*.' ImgExt]))
else
    mkdir(fullfile(BaseDir,ChunkDirName))
end
% Create Chunked images 
% Read raw logo images
Files = dir(fullfile(LogoImgDir,['*.' ImgExt]));
for f = 1:length(Files)
    im = (imread(fullfile(LogoImgDir,Files(f).name)));  % Read img and convert to grayscale
    if length(size(im)) > 2, im = rgb2gray(im); end;
    if ChunkImage == 1
        % Divide the image into square chunks
        imgSz = size(im);
        [StepVal,MinDim] = min(imgSz);
        [MaxVal,MaxDim] = max(imgSz);
        cc = 1;
        for c = 1:round(StepVal*0.4):MaxVal     % Chunk
            if MinDim == 1
                Rows = [1 imgSz(1)];Cols = [c c+imgSz(1)-1];
            else
                Rows = [c c+imgSz(2)-1];Cols = [1 imgSz(2)];
            end
            % If we are at the end of the image (let the final block end at the end of image
            if Rows(2) > imgSz(1), Rows = [imgSz(1)-StepVal+1 imgSz(1)]; end
            if Cols(2) > imgSz(2), Cols = [imgSz(2)-StepVal+1 imgSz(2)]; end
            % Chunk
            Chunk = im(Rows(1):Rows(2),Cols(1):Cols(2));
            FileNameToSave = [Files(f).name '_Chunk_' num2str(cc) '.' ImgExt];
            imwrite(Chunk,fullfile(BaseDir,ChunkDirName,FileNameToSave),ImgExt);
            cc=cc+1;
            % If the end is reached
            if (Rows(2) == imgSz(1) && MinDim == 2) || (Cols(2) == imgSz(2) & MinDim == 1)
                break;
            end
        end
    else    % Just copy over original image to chunked directory
        imwrite(im,fullfile(BaseDir,ChunkDirName,Files(f).name));
    end
end

if ChunkImage == 1, fprintf(['\nImg chunked and saved to ' ChunkDirName ' in the base directory \n']); end

%% If Test Image Set (Limit the params to extremes)
if TestRun == 1
    Rotations = [Rotations(1) Rotations(end)];
    GaussianBlurStd = [GaussianBlurStd(1) GaussianBlurStd(end)];
    MotionBlurLength = [MotionBlurLength(1) MotionBlurLength(end)];
    BackGround_Transparency = [BackGround_Transparency(1) BackGround_Transparency(end)];
end
    
%% Load Background images

BackgroundImgs = dir(fullfile(BackImgDir,['*.' ImgExt]));
BGs = struct;
for b = 1:length(BackgroundImgs)
    bgim = imread(fullfile(BackImgDir,BackgroundImgs(b).name));
    if length(size(bgim)) > 2, bgim = rgb2gray(bgim); end   % Convert to gray scale if needed
    BGs(b).img = bgim;
end

%% Generate synthetic images of variations rotations

% Get images from the chunked directory and
%1. Rotate image
%2. Overlay background image
%3. Add gaussian blur
%4. Add motion blur
%5. Save to file

% Generate Directory to save image
OutDirName = 'SyntheticLogos';   % Name of the directory saving chunked images
if isdir(fullfile(BaseDir,OutDirName))
    delete(fullfile(BaseDir,OutDirName,['*.' ImgExt]))
else
    mkdir(fullfile(BaseDir,OutDirName))
end
% Iterate through images
ChunkedImgs = dir(fullfile(BaseDir,ChunkDirName,['*.' ImgExt]));
TotalImages = length(ChunkedImgs) * length(Rotations) * length(BGs) ...
    * length(BackGround_Transparency) * (length(GaussianBlurStd) + length(MotionBlurLength));
imgNo = 1;
tic;     % For tracking time
fprintf('\n Generating image variations ...\n');
k = 1;
for i = 1:length(ChunkedImgs)
    % Read in chunked image (and convert to gray scale if needed)
    img = imread(fullfile(BaseDir,ChunkDirName,ChunkedImgs(i).name));
    if length(size(img)) > 2, img = rgb2gray(bgim); end   % Convert to gray scale if needed
    
    for r = 1:length(Rotations)     % Apply rotations
        RotAngle = Rotations(r);
        % Get the rotated image
        RotImg = imrotate(img,RotAngle);
        
        for b = 1:length(BGs)    % Apply background images
            % Background img
            BGImg = BGs(b).img;
            for t = 1:length(BackGround_Transparency)   % Background transparency
                % Merge rotated image with the Background
                Alpha = BackGround_Transparency(t);
                sz_R  = size(RotImg);
                RotImg_W_BackGrnd = (1-Alpha)*RotImg + Alpha * BGImg(1:sz_R(1),1:sz_R(2));
                
                % Blurring (Gaussian and Motion Blurring applied separately)
                for g = 1:length(GaussianBlurStd)   % Gaussian Blur
                    GaussianBlur = fspecial('gaussian',GHSize, GaussianBlurStd(g));
                    imBlur = imfilter(RotImg_W_BackGrnd,GaussianBlur,'replicate');
                    imBlur = imresize(imBlur,FinalImgSize);
                    FileToSaveAs = ['Img_' num2str(imgNo) '.' ImgExt];;
                    imwrite(imBlur,fullfile(BaseDir,OutDirName,FileToSaveAs),ImgExt);                    
                    % Show progress report
                    if mod(imgNo,1000) == 0, fprintf('Generated %i of %i in %f s \n',imgNo,TotalImages,toc); end
                    imgNo = imgNo+1;
                end     % Gaussian Blur
                for m = 1:length(MotionBlurLength)  % Motion Blur
                    MotionBlur = fspecial('motion',MotionBlurLength(m),0);
                    imBlur = imfilter(RotImg_W_BackGrnd,GaussianBlur,'replicate');
                    imBlur = imresize(imBlur,FinalImgSize);
                    FileToSaveAs = ['Img_' num2str(imgNo) '.' ImgExt];;
                    imwrite(imBlur,fullfile(BaseDir,OutDirName,FileToSaveAs),ImgExt);
                    % Show progress report
                    if mod(imgNo,1000) == 0, fprintf('Generated %i of %i in %f s \n',imgNo,TotalImages,toc); end
                    imgNo = imgNo+1;
                end     % Motion blur    
                
            end     % Transparency                
        end     % Background image
    end     % Rotations   
end     % Chunked image
