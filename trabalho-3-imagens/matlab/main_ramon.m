%% Initialize
if ~(exist('training'))
    load('data/training.mat')
end

posCollectionPath = 'img/positives/';
negCollectionPath = 'img/negatives/';


%% Read the file containing the indices of the positive test images

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

%% Bounding Boxes
somaErrosQuadrados = zeros(1,4);
numberValidPictures = zeros(1,4);

% indices of pictures to be used for testing: at first, they do
% not have NAN entries
indicesWithoutNAN = 1:100; % find(posIndices(:,2)<2284);

% index of picture to be used in real vs detected illustration is
% picked randomly from indicesWithoutNAN
indexPicToBeShown = 50; %randi( [indicesWithoutNAN(1) indicesWithoutNAN(end)] );

clear IFaces

for i = 1:length(posIndices)
    
    iImage = posIndices(i,2);
    
    filename = [posCollectionPath, 'img', num2str(iImage, '%1.4d'), '.png'];
    
    % Print name for every 100 images
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
    
    any(isnan(mouth_left_corner)) || any(isnan(mouth_right_corner)) || ...
        any(isnan(mouth_center_top_lip)) || any(isnan(
    
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
    
    % Define the real box vector [x, y, width, height]:
    real_box = [topLeftCornerX, ...
        topLeftCornerY, ...
        realBox_width, ...
        realBox_height];
    
    % Detect applyin Viola-Jones identification:
    detected_boxes = step(detector, I);
    
    % Find the box with the maximum Y coordinate:
    [box_y_max, iBoxMaxY] = max(detected_boxes(:,2));
    
    % The mouth box is the one with the highest Y:
    detected_box_mouth = detected_boxes(iBoxMaxY, :);
    
    
    % process picture only if both the real and detected boxes
    % do not have NaN entries and if their sizes are greater than 0
    if ( ~any(size(detected_box_mouth)==0) && ~any(size(real_box)==0) )
        
        % Top left and bottom right coordinates:
        detectedBox_topLeft = detected_box_mouth(1:2);
        detectedBox_bottomRight = detectedBox_topLeft + detected_box_mouth(3:4);
        
        % Check the detected box height and width:
        detectedBox_height = detectedBox_bottomRight(2) - ...
            detectedBox_topLeft(2);
        detectedBox_width = detectedBox_bottomRight(1) - ...
            detectedBox_topLeft(1);
        
        % Sanity check:
        if (detectedBox_height < 0 || detectedBox_width < 0 )
            error('Negative Height or Width');
        end
        
        % Find the same 4 points of interest on the image:
        detected_mouth_right_corner = detectedBox_topLeft + [0, detectedBox_height/2];
        detected_mouth_left_corner = detectedBox_bottomRight - [0, detectedBox_height/2];
        detected_mouth_center_top_lip = detectedBox_topLeft + [detectedBox_width/2 0];
        detected_mouth_center_bottom_lip = detectedBox_topLeft + ...
            [detectedBox_width/2 detectedBox_height];
        
        
        % Save number of valid pictures in a vector
        % Save also the sum of the erros in each coordinate in a vector
        % Vector order: [leftCorner, bottomCenter, rightCorder, topCenter]
        
        % Mouth Left Corner:
        error_leftCorner = 0;
        if ( ~any(isnan(detected_mouth_left_corner)) && ...
                ~any(isnan(mouth_left_corner)) )
            % Increment number of valid images:
            numberValidPictures(1) = numberValidPictures(1) + 1;
            error_leftCorner = sqrt( sum(abs(detected_mouth_left_corner ...
                - mouth_left_corner).^2) );
        end
        
        % Mouth Bottom Lip Center:
        error_bottomCenter = 0;
        if ( ~any(isnan(detected_mouth_center_bottom_lip)) && ...
                ~any(isnan(mouth_center_bottom_lip)) )
            numberValidPictures(2) = numberValidPictures(2) + 1;
            error_bottomCenter = sqrt( sum(abs(detected_mouth_center_bottom_lip - ...
                mouth_center_bottom_lip).^2) );
        end
        
        % Mouth Right Corner:
        error_rightCorner = 0;
        if ( ~any(isnan(detected_mouth_right_corner)) && ...
                ~any(isnan(mouth_left_corner)) )
            % Increment number of valid images:
            numberValidPictures(3) = numberValidPictures(3) + 1;
            error_rightCorner = sqrt( sum(abs(detected_mouth_right_corner ...
                - mouth_right_corner).^2) );
        end
        
        % Mouth Top Lip Center:
        error_topCenter = 0;
        if ( ~any(isnan(detected_mouth_center_top_lip)) && ...
                ~any(isnan(mouth_center_top_lip)) )
            numberValidPictures(4) = numberValidPictures(4) + 1;
            error_topCenter = sqrt( sum(abs(detected_mouth_center_top_lip - ...
                mouth_center_top_lip).^2) );
        end
        
        % Sum of the errors:
        somaErrosQuadrados = somaErrosQuadrados + ...
            [error_leftCorner error_bottomCenter error_rightCorner error_topCenter];
        
    end
end

% Mean error:
RMSEs = sqrt(somaErrosQuadrados ./ numberValidPictures);
RMSE_global = mean(RMSEs)


%% Check Detected Coordinates

% Real
imshow(insertMarker(I, [mouth_left_corner; ...
    mouth_right_corner; ...
    mouth_center_top_lip; ...
    mouth_center_bottom_lip]))

% Detected
imshow(insertMarker(I, [detected_mouth_left_corner; ...
    detected_mouth_right_corner; ...
    detected_mouth_center_top_lip; ...
    detected_mouth_center_bottom_lip]))

% Show detection:
IFaces = insertObjectAnnotation(I, 'rectangle', [real_box; detected_box_mouth], ...
    'Mouth', 'color', {'red', 'green'});
imshow(IFaces);
% Red -> real
% Green -> Estimated
