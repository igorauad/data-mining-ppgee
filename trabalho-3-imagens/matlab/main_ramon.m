%% Initialize
if ~(exist('training'))
    load('data/training.mat')
end

posCollectionPath = 'img/positives/';
negCollectionPath = 'img/negatives/';


%% read testIdx file containing the indices of positive images
% to be considered in the tests

% reads csv ignoring the first row
posIndices = csvread('data/testIdx_semAspas.csv', 1, 0);


%% Load detector
detector_choice = 'Matlab';

switch detector_choice
    case 'Matlab'
        detector = vision.CascadeObjectDetector('Mouth');
    case 'Ours'
        detector = vision.CascadeObjectDetector('mouthDetector.xml');
end

%% Average of the bounding boxes

% training é uma matriz contendo as reais posicoes das bocas nas imagens
% positivas
nImages = length(training);

for i = 1
    
end

%% Bounding Boxes
somaErrosQuadrados = zeros(1,4);
numberValidPictures = zeros(1,4);

% indices of pictures to be used for testing: at first, they do
% not have NAN entries
indicesWithoutNAN = 1:100; %find(posIndices(:,2)<2284);

% index of picture to be used in real vs detected illustration is
% picked randomly from indicesWithoutNAN
indexPicToBeShown = 50; %randi( [indicesWithoutNAN(1) indicesWithoutNAN(end)] );

clear IFaces

for i = indicesWithoutNAN(1):indicesWithoutNAN(end) %1:length(posIndices)
    
    iImage = posIndices(i,2);

    filename = [posCollectionPath, 'img', num2str(iImage, '%1.4d'), '.png'];
    
    if mod(i, 100)==1
        filename
    end
    
    I = training(iImage).Image / 255;
    %I = imread(filename);
    % Improve contrast
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
    
    realBox_width = sqrt(sum(abs(mouth_left_corner - mouth_right_corner).^2));
    realBox_height = sqrt(sum(abs(mouth_center_top_lip - mouth_center_bottom_lip).^2));
    
    % points of interest of the real bounding box
    realBox_topLeft = [topLeftCornerX topLeftCornerY];
    realBox_bottomRight = realBox_topLeft + [realBox_width realBox_height];
    realBox_topLip = mouth_center_top_lip;
    realBox_bottomLip = mouth_center_bottom_lip;
    
    real_box = [topLeftCornerX, ...
        topLeftCornerY, ...
        realBox_width, realBox_height];

    detected_boxes = step(detector, I);
    [box_y_max, iBoxMaxY] = max(detected_boxes(:,2));

    % the mouth box is the one with the highest Y
    detected_box_mouth = detected_boxes(iBoxMaxY, :);
    
    
    % process picture only if both the real and detected boxes
    % do not have NaN entries and if their sizes are greater than 0
    if ( ~any(size(detected_box_mouth)==0) && ~any(size(real_box)==0) )
        
        % the same 4 points of interest of the detected bounding box
        detectedBox_topLeft = detected_box_mouth(1:2);
        detectedBox_bottomRight = detectedBox_topLeft + detected_box_mouth(3:4);

        % the top lip is estimated to be in the middle of the upper
        % row of the box
        detectedBox_topLip = detectedBox_topLeft + ...
            [realBox_width/2.0 0];

        % the bottom lip is estimated to be in the middle of the lower
        % row of the box
        detectedBox_bottomLip = detectedBox_topLeft + ...
            [0 realBox_height/2.0];
        
        error_topLeft = 0;
        if ( ~any(isnan(detectedBox_topLeft)) && ~any(isnan(realBox_topLeft)) )
            numberValidPictures(1) = numberValidPictures(1) + 1;
            error_topLeft = sqrt( sum(abs(detectedBox_topLeft - realBox_topLeft).^2) );
        end
        
        error_bottomRight = 0;
        if ( ~any(isnan(detectedBox_bottomRight)) && ~any(isnan(realBox_bottomRight)) )
            numberValidPictures(2) = numberValidPictures(2) + 1;
            error_bottomRight = sqrt( sum(abs(detectedBox_bottomRight - realBox_bottomRight).^2) );
        end
        
        error_topLip = 0;
        if ( ~any(isnan(detectedBox_topLip)) && ~any(isnan(realBox_topLip)) )
            numberValidPictures(3) = numberValidPictures(3) + 1;
            error_topLip = sqrt( sum(abs(detectedBox_topLip - realBox_topLip).^2) );
        end
        
        error_bottomLip = 0;
        if ( ~any(isnan(detectedBox_bottomLip)) && ~any(isnan(realBox_bottomLip)) )
            numberValidPictures(4) = numberValidPictures(4) + 1;
            error_bottomLip = sqrt( sum(abs(detectedBox_bottomLip - realBox_bottomLip).^2) );
        end
        
        
        somaErrosQuadrados = somaErrosQuadrados + ...
        [error_topLeft error_bottomRight error_topLip error_bottomLip];

        
        if (i == indexPicToBeShown)
            IFaces = insertObjectAnnotation(I, 'rectangle', [real_box; detected_box_mouth], ...
                'Mouth', 'color', {'red', 'green'});
            % Red -> real
            % Green -> Estimated
        end
    end
end

imshow(IFaces);

media = somaErrosQuadrados ./ numberValidPictures;
RMSEs = sqrt(media);
RMSE_global = mean(RMSEs)

