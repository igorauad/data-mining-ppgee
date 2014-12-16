load('data/training.mat')

feature = 'mouth_center_bottom_lip';
negCollectionPath = 'img/negatives/';
posCollectionPath = 'img/positives/';

nTraining = length(training);

feature_x = [feature, '_x'];
feature_y = [feature, '_y'];

% Imagens usadas para teste no R
testIdx = csvread('data/testIdx_semAspas.csv', 1, 0);
trainIdx = setdiff((1:nTraining).', testIdx(:,2));

% Actual training set:
training = training(trainIdx);

%% Plot gallery

for i = 1:25
    subplot(5,5,i)
    imshow(training(i).Image/255)
end

%% Inspect image

iImage = 40;

I = training(iImage).Image / 255;
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

subplot(211)
IMouth = insertObjectAnnotation(I, 'rectangle', bbox, 'Mouth');
imshow(IMouth)

subplot(212)
IFaces = insertMarker(I, [mouth_left_corner; mouth_right_corner; ...
    mouth_center_top_lip; mouth_center_bottom_lip]);
imshow(IFaces)


%% Positive Images

nImages = length(training);

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
    
    positiveData(iImage).imageFilename = [posCollectionPath, 'img', num2str(trainIdx(iImage), '%1.4d'), '.png'];
    positiveData(iImage).objectBoundingBoxes = bbox;
end

% Post-processing:
% Detect NaNs in the objectBoundingBoxes and detect bounding boxes beyond
% the image limits
del_ix = []; % Indexes whose images should be removed from training set
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

% Effectively remove image entrys containin NaNs:
positiveData(del_ix) = [];

%% Exclude exceptions
exceptions = [1451];  
positiveData(exceptions) = [];

%% Inspect one rectangle from "positiveData" struct array

iImg = 1451;

I = imread(positiveData(iImg).imageFilename);
IMouth = insertObjectAnnotation(I, 'rectangle', positiveData(iImg).objectBoundingBoxes, 'Mouth');
imshow(IMouth)

%% Train detector

trainCascadeObjectDetector('mouthDetectorLBP.xml', positiveData, negCollectionPath, ...
    'FalseAlarmRate', 0.4, ...
    'NumCascadeStages', 7, ...
    'FeatureType', 'LBP');
