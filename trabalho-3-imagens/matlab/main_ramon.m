%% Initialize
if ~(exist('training'))
    load('data/training.mat')
end

posCollectionPath = 'img/positives/';
negCollectionPath = 'img/negatives/';



%% Load detector
% detector_choice = 'Mouth'; % MATLAB's mouth classifier
% detector_choice = 'mouthDetector_FAR0.2_numStages5.xml';
detector_choice = 'mouthDetector_FAR0.2_numStages10(7estagios).xml';


detector = vision.CascadeObjectDetector(detector_choice);


%% Bounding Boxes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% indices of positive test images %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searchVector = load('posTestIndices.txt');

% % test the 20% positive images that were not used in the training process
% [posDataIndices, posDataFilenames] = ...
%     textread('positiveData.txt', '%d %s', 'delimiter', '\n');
% 
% 
% posTrainIndices = load('posTrainIndices.txt');
% 
% % the test indices are those not present in posTrainIndices array
% positiveDataTestIndices = setxor(posDataIndices, posTrainIndices);
% 
% % correct positive image indices (this file will be used in R!!!)
% pfpos_correct = fopen('posTrainIndices_correct.txt', 'w');
% 
% searchVector = zeros(1, length(positiveDataTestIndices));
% 
% % get indices of images from filenames
% for i=1:length(positiveDataTestIndices)
%     positiveFilename = char( posDataFilenames(positiveDataTestIndices(i)) );
%     searchVector(i) = str2num(positiveFilename(18:21));
% 
%     fprintf(pfpos_correct, '%d\n', searchVector(i));
% end
% 
% fclose(pfpos_correct);


somaErrosQuadrados = zeros(1,4);
numberValidPictures = zeros(1,4);


truePositives = 0;
falseNegatives = 0;


% quantity of positive images with valid detected and real bounding boxes
qtyValidRealDetectedPositives = 0;

% quantity of positive images with valid real mouth box
qtyValidRealPositives = 0;


% index of positive picture to be shown
indexPosPicToBeShown = searchVector( randi( [1, length(searchVector)] ) );

truePositivesIndices = zeros(1, length(searchVector));
falseNegativesIndices = zeros(1, length(searchVector));

for i = 1:length(searchVector)
    
    iImage = searchVector(i);
    
    filename = [posCollectionPath, 'img', num2str(iImage, '%1.4d'), '.png'];
    
    % Print name for every 100 images
    if mod(i, 100)==1
        filename
    end
    
    I = training(iImage).Image / 255;
    %I = imread(filename);
    % Improve contrast
    I = imadjust(I);
    
    % remove average and normalize image variance to unity (as suggested in
    % Viola-Jones' 2001 paper)
    %I = double(I);
    %I = I - mean(I(:));
    %I = I / std(I(:),0,1);
    
    % Mouth coordinates
    mouth_left_corner(1) = training(iImage).mouth_left_corner_x;
    mouth_left_corner(2) = training(iImage).mouth_left_corner_y;
    mouth_right_corner(1) = training(iImage).mouth_right_corner_x;
    mouth_right_corner(2) = training(iImage).mouth_right_corner_y;
    mouth_center_top_lip(1) = training(iImage).mouth_center_top_lip_x;
    mouth_center_top_lip(2) = training(iImage).mouth_center_top_lip_y;
    mouth_center_bottom_lip(1) = training(iImage).mouth_center_bottom_lip_x;
    mouth_center_bottom_lip(2) = training(iImage).mouth_center_bottom_lip_y;
    
    
    % discard image if any of the mouth coordinates are NaNs
    if any(isnan(mouth_left_corner)) || any(isnan(mouth_right_corner)) ...
            || any(isnan(mouth_center_top_lip)) || any(isnan(mouth_center_bottom_lip))
        
        continue;
        
    end
    
    
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

    
    qtyValidRealPositives = qtyValidRealPositives + 1;
    
    % Detect mouth applying Viola-Jones identification:
    detected_boxes = step(detector, I);
    
    % Find the box with the maximum Y coordinate:
    [box_y_max, iBoxMaxY] = max(detected_boxes(:,2));
    
    % The mouth box is the one with the highest Y:
    detected_box_mouth = detected_boxes(iBoxMaxY, :);
    
    
    if any(size(detected_box_mouth)==0) || any(isnan(detected_box_mouth))
        mouthDetected = false;
        
    else % the detected mouth box is valid
        
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
        
        
        % the real and detected bounding boxes do not intersect
        if detectedBox_bottomRight(2)<realBox_topLeft(2) || ...
                detectedBox_topLeft(2)>realBox_bottomRight(2) || ...
                detectedBox_bottomRight(1)<realBox_topLeft(1) || ...
                detectedBox_topLeft(1)>realBox_bottomRight(1)
            
            mouthDetected = false;
            
        else
            
            mouthDetected = true;
            
        end
        
    end
    
    
    % count truePositive and falseNegatives occurrences
    if mouthDetected==true
        truePositives = truePositives + 1;
        
        % record the ids of the false negative images
        truePositivesIndices(truePositives) = iImage;
    else
        
        falseNegatives = falseNegatives + 1;
        
        % record the ids of the false negative images
        falseNegativesIndices(falseNegatives) = iImage;
    end
    
    
    
%     % process picture only if both the real and detected boxes
%     % do not have NaN entries and if their sizes are greater than 0
%     if ( ~any(size(detected_box_mouth)==0) && ~any(size(real_box)==0) )
        
        
    % accumulate the RMSE only if the detected box does not have NaN
    % entries and if its size is greater than 0
    if ( ~any(size(detected_box_mouth)==0) && ~any(isnan(detected_box_mouth)) )
        
        
        % Find the same 4 points of interest (left and right mouth
        % corners, upper and lower lip centers) on the image:
        detected_mouth_right_corner = detectedBox_topLeft + [0, detectedBox_height/2];
        detected_mouth_left_corner = detectedBox_bottomRight - [0, detectedBox_height/2];
        detected_mouth_center_top_lip = detectedBox_topLeft + [detectedBox_width/2 0];
        detected_mouth_center_bottom_lip = detectedBox_topLeft + ...
            [detectedBox_width/2, detectedBox_height];
        
        
        % Save number of valid pictures in a vector
        % Save also the sum of the errors in each coordinate in a vector
        % Vector order: [leftCorner, bottomCenter, rightCorner, topCenter]
        
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
                ~any(isnan(mouth_right_corner)) )
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
            [error_leftCorner, error_bottomCenter, error_rightCorner, error_topCenter];
        
        
        % if all errors are different than zero, it means that all features
        % were detected.
        if error_leftCorner~=0 && error_bottomCenter~=0 && ...
                error_rightCorner~=0 && error_topCenter~=0
            
            qtyValidRealDetectedPositives = qtyValidRealDetectedPositives + 1;
            
            %if qtyValidRealDetectedPositives == indexPicToBeShown
            if iImage == indexPosPicToBeShown
            
            % para mostrar a imagem que aparece no slide 18 da apresentacao
            %if iImage == 231
                picToBeShownI = I;
                
                picToBeShownRealRectangles = ...
                    [mouth_left_corner; ...
                    mouth_right_corner; ...
                    mouth_center_top_lip; ...
                    mouth_center_bottom_lip];
                
                picToBeShownDetectedRectangles = ...
                    [detected_mouth_left_corner; ...
                    detected_mouth_right_corner; ...
                    detected_mouth_center_top_lip; ...
                    detected_mouth_center_bottom_lip];
                
                picToBeShownRealRectangle = real_box;
                picToBeShownMouthBox = detected_box_mouth;
            end
            
        end
        
    end
end



%% Calculation of RMSEs and positive/negative ratios

% Root Mean Square Error:
RMSEs_4cantos_boca = sqrt(somaErrosQuadrados ./ numberValidPictures)
RMSE_global = mean(RMSEs_4cantos_boca)


% truncate truePositivesIndices and falseNegativesIndices vectors
% to contain only non-zero entries
truePositivesIndices = truePositivesIndices(1:truePositives);
falseNegativesIndices = falseNegativesIndices(1:falseNegatives);

% true positive rate (TPR)
%TPR = 100.0 * truePositives / length(searchVector);
TPR = 100.0 * truePositives / qtyValidRealPositives;

% false negative rate (FNR)
%FNR = 100.0 * falseNegatives / length(searchVector);
FNR = 100.0 * falseNegatives / qtyValidRealPositives;

fprintf('\nTrue Positive Rate (TPR) = %f %%\n', TPR);
fprintf('False Negative Rate (FNR) = %f %%\n', FNR);


%% Check Detected Coordinates
    

clear IFaces


% Real
IFaces = insertMarker(picToBeShownI, picToBeShownRealRectangles, 'Color', 'red', 'Size', 2);

% Detected
IFaces = insertMarker(IFaces, picToBeShownDetectedRectangles, 'o', 'Color', 'green', 'Size', 2);

figure(1);
imshow(IFaces);

% Show detection:
IFaces = insertObjectAnnotation(picToBeShownI, 'rectangle', ...
    [picToBeShownRealRectangle; picToBeShownMouthBox], ...
    'Mouth', 'color', {'red', 'green'});
figure(2);
imshow(IFaces);


% Red -> real
% Green -> Estimated

