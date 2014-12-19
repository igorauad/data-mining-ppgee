%% Initialize

posCollectionPath = 'img/positives/';
negCollectionPath = 'img/negatives/';


%% Load detector
% detector_choice = 'Mouth'; % MATLAB's mouth classifier
% detector_choice = 'mouthDetector_FAR0.2_numStages5.xml';
detector_choice = 'mouthDetector_FAR0.2_numStages10(7estagios).xml';

detector = vision.CascadeObjectDetector(detector_choice);


%% Bounding Boxes

falsePositives = 0;
trueNegatives = 0;


%searchVector = load('allnegIndices.txt');


% indices of negative test pictures
searchVector = load('negTestIndices.txt');


% index of negative picture to be shown
indexNegPicToBeShown = randi( [1, 100] );

falsePositivesIndices = zeros(1, length(searchVector));
trueNegativesIndices = zeros(1, length(searchVector));

for i = 1:length(searchVector)
    
    iImage = searchVector(i);
    
    filename = [negCollectionPath, 'neg-', num2str(iImage, '%1.4d'), '.jpg'];
    
    % Print name for every 100 images
    if mod(i, 100)==1
        filename
    end
    
    I = imread(filename);
    % Improve contrast
    I = imadjust(I);
    
    % remove average and normalize image variance to unity (as suggested in
    % Viola-Jones' 2001 paper)
    %I = double(I);
    %I = I - mean(I(:));
    %I = I / std(I(:),0,1);
    
    
    
    % Detect mouth applying Viola-Jones identification:
    detected_boxes = step(detector, I);
    
    % Find the box with the maximum Y coordinate:
    [box_y_max, iBoxMaxY] = max(detected_boxes(:,2));
    
    % The mouth box is the one with the highest Y:
    detected_box_mouth = detected_boxes(iBoxMaxY, :);
    
    
    % if detected_box_mouth is not a valid rectangle,
    % then it is a true negative
    if any(size(detected_box_mouth)==0) || any(isnan(detected_box_mouth))
        mouthDetected = false;
        
    else
        
        mouthDetected = true;
        
    end
    
    
    % count falsePositive and trueNegative occurrences
    if mouthDetected == true
        falsePositives = falsePositives + 1;
        
        % record the indices of the false positive images
        falsePositivesIndices(falsePositives) = iImage;
        
        if falsePositives == indexNegPicToBeShown
            imageToBeShown = I;
            
            % Top left and bottom right coordinates:
            detectedBox_topLeft = detected_box_mouth(1:2);
            detectedBox_bottomRight = detectedBox_topLeft + detected_box_mouth(3:4);
            
            % Calculate the detected box height and width:
            detectedBox_height = detectedBox_bottomRight(2) - ...
                detectedBox_topLeft(2);
            detectedBox_width = detectedBox_bottomRight(1) - ...
                detectedBox_topLeft(1);
            
            % Width and Height Sanity check:
            if (detectedBox_height < 0 || detectedBox_width < 0 )
                error('Negative Height or Width');
            end
            
            % Find the same 4 points of interest (left and right mouth
            % corners, upper and lower lip centers) on the image:
            detected_mouth_right_corner = detectedBox_topLeft + [0, detectedBox_height/2];
            detected_mouth_left_corner = detectedBox_bottomRight - [0, detectedBox_height/2];
            detected_mouth_center_top_lip = detectedBox_topLeft + [detectedBox_width/2 0];
            detected_mouth_center_bottom_lip = detectedBox_topLeft + ...
                [detectedBox_width/2 detectedBox_height];
            
            
            
            imageToBeShownDetectedMouthFeatures = ...
                [detected_mouth_left_corner; ...
                detected_mouth_right_corner; ...
                detected_mouth_center_top_lip; ...
                detected_mouth_center_bottom_lip];
            
            imageToBeShownMouthBox = detected_box_mouth;
            
        end
        
    else
        
        trueNegatives = trueNegatives + 1;
        
        % record the indices of the false negative images
        trueNegativesIndices(trueNegatives) = iImage;
        
    end
    
    
end



%% Calculation of RMSEs and positive/negative ratios

% truncate falsePositivesIndices and trueNegativesIndices vectors
% to contain only non-zero entries
falsePositivesIndices = falsePositivesIndices(1:falsePositives);
trueNegativesIndices = trueNegativesIndices(1:trueNegatives);

% false positive rate (FPR)
FPR = 100.0 * falsePositives / length(searchVector);

% true negative rate (TNR)
TNR = 100.0 * trueNegatives / length(searchVector);

fprintf('\nFalse Positive Rate (FPR) = %f %%\n', FPR);
fprintf('True Negative Rate (TNR) = %f %%\n', TNR);


%% Show a false positive picture

clear IFaces


% Detected
IFaces = insertMarker(imageToBeShown, imageToBeShownDetectedMouthFeatures, 'o', 'Color', 'green', 'Size', 2);

figure(1);
imshow(IFaces);

% Show detection:
IFaces = insertObjectAnnotation(imageToBeShown, 'rectangle', ...
    [imageToBeShownMouthBox], ...
    'Mouth', 'color', {'green'});
figure(2);
imshow(IFaces);


% Red -> real
% Green -> Estimated

