if ~(exist('training'))
    load('data/training.mat')
end

nImages = length(training);

feature = 'mouth_center_bottom_lip';
negCollectionPath = 'img/negatives/';
posCollectionPath = 'img/positives/';

nTraining = length(training);

feature_x = [feature, '_x'];
feature_y = [feature, '_y'];

% Inspected exceptions (obtained with findOutliers.m)
exceptions = [1586 1602 1613 1625 1637 1640 1658 1685 1694 1699 1722 1867 1908];

% % Remove them:
% training(exceptions) = [];


%% Plot gallery

for i = 1:25
    subplot(5,5,i)
    imshow(training(i).Image/255)
end

%% Inspect image

iImage = 1908;

filename = [posCollectionPath, 'img', num2str(iImage, '%1.4d'), '.png'];
I = imread(filename);
I = imadjust(I);

% Mouth coordinates
mouth_left_corner(1) = training(iImage).mouth_left_corner_x;
mouth_left_corner(2) = training(iImage).mouth_left_corner_y;
mouth_right_corner(1) = training(iImage).mouth_right_corner_x;
mouth_right_corner(2) = training(iImage).mouth_right_corner_y;
mouth_center_top_lip(1) = training(iImage).mouth_center_top_lip_x;
mouth_center_top_lip(2) = training(iImage).mouth_center_top_lip_y;
mouth_center_bottom_lip(1) = training(iImage).mouth_center_bottom_lip_x;
mouth_center_bottom_lip(2) = training(iImage).mouth_center_bottom_lip_y;

% Bounding box dimensions and coordinates
topLeftCornerX = mouth_right_corner(1);
topLeftCornerY = mouth_center_top_lip(2);
box_width = sqrt(sum(abs(mouth_left_corner - mouth_right_corner).^2));
box_height = sqrt(sum(abs(mouth_center_top_lip - mouth_center_bottom_lip).^2));
% Add some margin to the box
topLeftCornerX = topLeftCornerX - 0.1*box_width;
topLeftCornerY = topLeftCornerY + 0.05*box_height;
box_width = 1.2*box_width;
box_height = 1.1*box_height;

bbox = [topLeftCornerX, ...
    topLeftCornerY, ...
    box_width, box_height];

subplot(121)
IMouth = insertObjectAnnotation(I, 'rectangle', bbox, 'Mouth');
imshow(IMouth)

subplot(122)
IFaces = insertMarker(I, [mouth_left_corner; mouth_right_corner; ...
    mouth_center_top_lip; mouth_center_bottom_lip]);
imshow(IFaces)


%% Positive Images

nImages = length(training);

clear positiveData

for iImage = 1:nImages
    % Mouth coordinates
    mouth_left_corner(1) = training(iImage).mouth_left_corner_x;
    mouth_left_corner(2) = training(iImage).mouth_left_corner_y;
    mouth_right_corner(1) = training(iImage).mouth_right_corner_x;
    mouth_right_corner(2) = training(iImage).mouth_right_corner_y;
    mouth_center_top_lip(1) = training(iImage).mouth_center_top_lip_x;
    mouth_center_top_lip(2) = training(iImage).mouth_center_top_lip_y;
    mouth_center_bottom_lip(1) = training(iImage).mouth_center_bottom_lip_x;
    mouth_center_bottom_lip(2) = training(iImage).mouth_center_bottom_lip_y;
    
    % Bounding box dimensions and coordinates
    topLeftCornerX = mouth_right_corner(1);
    topLeftCornerY = mouth_center_top_lip(2);
    box_width = sqrt(sum(abs(mouth_left_corner - mouth_right_corner).^2));
    box_height = sqrt(sum(abs(mouth_center_top_lip - mouth_center_bottom_lip).^2));
    
    % Add some margin to the box
    topLeftCornerX = topLeftCornerX - 0.1*box_width;
    topLeftCornerY = topLeftCornerY + 0.05*box_height;
    box_width = 1.2*box_width;
    box_height = 1.1*box_height;
    
    bbox = [topLeftCornerX, ...
        topLeftCornerY, ...
        box_width, box_height];
    
    positiveData(iImage).imageFilename = [posCollectionPath, 'img', num2str(iImage, '%1.4d'), '.png'];
    positiveData(iImage).objectBoundingBoxes = bbox;
end


% Delete exceptions from positiveData
positiveData(exceptions) = [];

nImages = length(positiveData);

% Post-processing:
% Detect NaNs in the objectBoundingBoxes and detect bounding boxes beyond
% the image limits
del_ix = []; % Indices of images that should be removed from training set
for iImage = 1:nImages
    
    bboxes = positiveData(iImage).objectBoundingBoxes;
    
    % First check for any NaN or negative values
    if ( any(isnan(bboxes)) || any(bboxes < 0) )
        fprintf('Removed image %d due to NaN or neg\n', iImage);
        del_ix = union(del_ix, iImage);
        
    else
        % Then check any bounding box beyond image limits
        right_corner = bboxes(1) + bboxes(3);
        bottom_corner = bboxes(2) - bboxes(4);
        upper_corner = bboxes(2) + bboxes(4);
        box_width = bboxes(3);
        box_height = bboxes(4);
        
        if (right_corner > 96)
            fprintf('Adjusted bbox width of image %d \n', iImage);
            bboxes(3) = 96 - bboxes(1);
            positiveData(iImage).objectBoundingBoxes = bboxes;
        end
        
        if (bottom_corner < 0)
            fprintf('Adjusted bbox height of image %d \n', iImage);
            bboxes(4) = bboxes(2);
            positiveData(iImage).objectBoundingBoxes = bboxes;
        end
        
        if (upper_corner > 96)
            fprintf('Adjusted bbox height of image %d \n', iImage);
            bboxes(4) = 96 - bboxes(2);
            positiveData(iImage).objectBoundingBoxes = bboxes;
        end
        
        % Remove images for which the bounding boxes are less than a pixel
        if (box_width < 1 || box_height < 1)
            del_ix = union(del_ix, iImage);
        end
    end
end


% Effectively remove image entries containing NaNs:
positiveData(del_ix) = [];


% % record the names of the positive images that were not
% % filtered out
% pfvalid = fopen('positiveData.txt', 'w');
%
% for i = 1:length(positiveData)
%     fprintf(pfvalid, '%d %s\n', i, positiveData(i).imageFilename);
%     %fprintf(pfvalid, '%s\n', positiveData(i).imageFilename);
% end
%
% fclose(pfvalid);


% record the indices of the negative images

% the highest index (neg-index.jpg) among the negative images
maxNumberNegative = 4875;


allnegIndices = zeros(1, maxNumberNegative);
contNegatives = 0;

% check which negative images there are in the negatives folder
for i=1:maxNumberNegative
    filename = [negCollectionPath, 'neg-', num2str(i, '%1.4d'), '.jpg'];
    
    if exist(filename) ~= 0
        contNegatives = contNegatives + 1;
        allnegIndices(contNegatives) = i;
    end
    
end

allnegIndices = allnegIndices(1:contNegatives);


% record to this file all the actual indices (neg-index.jpg)
% of the negative images
pfallneg = fopen('allnegIndices.txt', 'w');
%for negIndex = allnegIndices
for i = 1:length(allnegIndices)
    %fprintf(pfallneg, '%d\n', negIndex);
    fprintf(pfallneg, '%d\n', allnegIndices(i));
end

fclose(pfallneg);



%% Train detectors

% generate indices of positive and negative training images only if the
% files containing these indices do not exist
if exist('posTrainIndices.txt','file')==0 || exist('negTrainIndices.txt','file')==0
    % the indices of the positive training images are picked randomly
    % from 80% of positiveData array
    positiveDataTrainIndices = randperm( length(positiveData), round(0.80*length(positiveData)) );
    positiveDataTestIndices = setxor( 1:length(positiveData), positiveDataTrainIndices );
    
    
    posTrainIndices = zeros(1, length(positiveDataTrainIndices));
    posTestIndices = zeros(1, length(positiveDataTestIndices));
    
    
    % record the indices of the positive and negative
    % training images to file
    pftrainpos = fopen('posTrainIndices.txt', 'w');
    pftestpos = fopen('posTestIndices.txt', 'w');
    pfposdatatrain = fopen('positiveDataTrainIndices.txt', 'w');
    for i = 1:length(positiveDataTrainIndices)
        fprintf(pfposdatatrain, '%d\n', positiveDataTrainIndices(i));
        
        posTrainIndices(i) = str2num( positiveData(positiveDataTrainIndices(i)).imageFilename( (end-7):(end-4) ) );
        
        fprintf(pftrainpos, '%d\n', posTrainIndices(i));
    end
    
    for i = 1:length(positiveDataTestIndices)
        posTestIndices(i) = str2num( positiveData(positiveDataTestIndices(i)).imageFilename( (end-7):(end-4) ) );
        
        fprintf(pftestpos, '%d\n', posTestIndices(i));
    end
    
    
    fclose(pftrainpos);
    fclose(pftestpos);
    fclose(pfposdatatrain);
    
    
    % the indices of the negative training images are picked randomly
    % from 80% of allnegIndices
    allnegTrainIndices = randperm( length(allnegIndices), round(0.80*length(allnegIndices)) );
    
    allnegTestIndices = setxor( 1:length(allnegIndices), allnegTrainIndices );
    
    pftrainneg = fopen('negTrainIndices.txt', 'w');
    pftestneg = fopen('negTestIndices.txt', 'w');
    
    negTrainIndices = zeros(1, length(allnegTrainIndices));
    for i = 1:length(allnegTrainIndices)
        negTrainIndices(i) = allnegIndices( allnegTrainIndices(i) );
        fprintf( pftrainneg, '%d\n', negTrainIndices(i) );
    end
    
    negTestIndices = zeros(1, length(allnegTestIndices));
    for i = 1:length(allnegTestIndices)
        negTestIndices(i) = allnegIndices( allnegTestIndices(i) );
        fprintf( pftestneg, '%d\n', negTestIndices(i) );
    end
    
    
    fclose(pftrainneg);
    fclose(pftestneg);
    
end


positiveDataTrainIndices = load('positiveDataTrainIndices.txt');
%posTrainIndices = load('posTrainIndices.txt');
negTrainIndices = load('negTrainIndices.txt');

clear negTrainFilenames
cont = 0;

for i = 1:length(negTrainIndices)
    cont = cont + 1;
    negTrainFilenames{cont} = [negCollectionPath, 'neg-', num2str(negTrainIndices(i), '%1.4d'), '.jpg'];
end



numDetectors = 3;
numStages = [5 10 20];
times = zeros(1, numDetectors);
for i=1:numDetectors

    %False alarm rate (FAR)
    FAR = 0.20;

    % true positive rate (TPR)
    TPR = 0.995;

    nameXML = ['mouthDetector_FAR' num2str(FAR) '_numStages' num2str(numStages(i)) '.xml']

    tic

    trainCascadeObjectDetector(nameXML, positiveData(positiveDataTrainIndices), negTrainFilenames, ...
        'FalseAlarmRate', FAR, ...
        'TruePositiveRate', TPR, ...
        'NumCascadeStages', numStages(i), ...
        'FeatureType', 'Haar', ...
        'ObjectTrainingSize', [20 40]);

    times(i) = toc;

end


