if ~(exist('training'))
    load('data/training.mat')
end


nImages = length(training);


feature = 'mouth_center_bottom_lip';
negCollectionPath = 'img/negatives/';
posCollectionPath = 'img/positives/';

nTraining = length(training);


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

subplot(211)
IMouth = insertObjectAnnotation(I, 'rectangle', bbox, 'Mouth');
imshow(IMouth)

subplot(212)
IFaces = insertMarker(I, mouth_left_corner, 'o', 'Color', 'red', 'Size', 2);
IFaces = insertMarker(IFaces, mouth_right_corner, 'x', 'Color', 'red', 'Size', 2);
IFaces = insertMarker(IFaces, mouth_center_top_lip, '+', 'Color', 'red', 'Size', 2);
IFaces = insertMarker(IFaces, mouth_center_bottom_lip, 's', 'Color', 'red', 'Size', 2);
imshow(IFaces)



%% Build positiveData: filename and bounding box of all positive images

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
    
    positiveData(iImage).imageFilename = [posCollectionPath, 'img', num2str(iImage, '%1.4d'), '.png'];
    positiveData(iImage).objectBoundingBoxes = bbox;
end


%% Post-processing:

% Detect NaNs in the objectBoundingBoxes and detect bounding boxes beyond
% the image limits

% Indices of images that should be filtered out
del_ix = [];

for iImage = 1:nImages
    
    bboxes = positiveData(iImage).objectBoundingBoxes;
    
    % First check for any NaN or negative values
    if ( any(isnan(bboxes)) || any(bboxes < 0) )
%         fprintf('Removed image %d due to NaN or neg\n', iImage);
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
            continue;
        end
        
        
    end
end


% Effectively remove image entries containing NaNs:
positiveData(del_ix) = [];


%% Detection of possible outliers

% indices of possible outliers
outlier_idx = [];

for i = 1:length(positiveData)
    
    % get image index (img-index.png) from filename
    iImage = str2num( positiveData(i).imageFilename( (end-7):(end-4) ) );
    
    
    
    % Eye coordinates
    left_eye_center(1) = training(iImage).left_eye_center_x;
    left_eye_center(2) = training(iImage).left_eye_center_y;
    right_eye_center(1) = training(iImage).right_eye_center_x;
    right_eye_center(2) = training(iImage).right_eye_center_y;
    
    % Nose coordinates
    nose_tip(1) = training(iImage).nose_tip_x;
    nose_tip(2) = training(iImage).nose_tip_y;
    
    % Mouth coordinates
    mouth_left_corner(1) = training(iImage).mouth_left_corner_x;
    mouth_left_corner(2) = training(iImage).mouth_left_corner_y;
    mouth_right_corner(1) = training(iImage).mouth_right_corner_x;
    mouth_right_corner(2) = training(iImage).mouth_right_corner_y;
    mouth_center_top_lip(1) = training(iImage).mouth_center_top_lip_x;
    mouth_center_top_lip(2) = training(iImage).mouth_center_top_lip_y;
    mouth_center_bottom_lip(1) = training(iImage).mouth_center_bottom_lip_x;
    mouth_center_bottom_lip(2) = training(iImage).mouth_center_bottom_lip_y;
    
    
    % tolerance for detecting if lips X coordinates is not within
    % the eyes X coordinates
    Tol = 0;
    
    if iImage == 1908
        mouth_left_corner
        mouth_right_corner
        mouth_center_top_lip
        mouth_center_bottom_lip
        left_eye_center
        right_eye_center
        error('parar');
    end
    
    
    % the Y coordinates of the mouth points should not be less than the
    % Y coordinates of the eye and nose points
    if      mouth_left_corner(2) < nose_tip(2) || ...
            mouth_left_corner(2) < left_eye_center(2) || ...
            mouth_left_corner(2) < right_eye_center(2) || ...
            mouth_right_corner(2) < nose_tip(2) || ...
            mouth_right_corner(2) < left_eye_center(2) || ...
            mouth_right_corner(2) < right_eye_center(2) || ...
            mouth_center_top_lip(2) < nose_tip(2) || ...
            mouth_center_top_lip(2) < left_eye_center(2) || ...
            mouth_center_top_lip(2) < right_eye_center(2) || ...
            mouth_center_bottom_lip(2) < nose_tip(2) || ...
            mouth_center_bottom_lip(2) < left_eye_center(2) || ...
            mouth_center_bottom_lip(2) < right_eye_center(2)
        
        isOutlier = true;
        
        
    % the X coordinates of the mouth points should be between
    % the left eye's and right eye's X coordinates (with tolerance of Tol pixels)
    elseif  mouth_center_bottom_lip(1) > left_eye_center(1)+Tol || ...
            mouth_center_bottom_lip(1) < right_eye_center(1)-Tol || ...
            mouth_center_top_lip(1) > left_eye_center(1)+Tol || ...
            mouth_center_top_lip(1) < right_eye_center(1)-Tol
        
        
        isOutlier = true;
        
    % the mouth points should form a rhombus
    elseif ~(mouth_right_corner(1)<mouth_center_bottom_lip(1) && ...
            mouth_right_corner(1)<mouth_center_top_lip(1) && ...
            mouth_center_bottom_lip(1)<mouth_left_corner(1) && ...
            mouth_center_top_lip(1)<mouth_left_corner(1)) ...
            || ...
            ~(mouth_center_top_lip(2)<mouth_left_corner(2) && ...
            mouth_center_top_lip(2)<mouth_right_corner(2) && ...
            mouth_left_corner(2)<mouth_center_bottom_lip(2) && ...
            mouth_right_corner(2)<mouth_center_bottom_lip(2))
        
        isOutlier = true;
        
    else
        
        isOutlier = false;
        
    end
    
    
    if isOutlier == true
        outlier_idx = union(outlier_idx, i);
    end
    
end

% Inspect possible outliers visually
for i = 1:length(outlier_idx)
    
    
    iImage = str2num( positiveData(outlier_idx(i)).imageFilename( (end-7):(end-4) ) );
    
    
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
    
    figure(1);
    subplot(211);
    IMouth = insertObjectAnnotation(I, 'rectangle', ...
        positiveData(outlier_idx(i)).objectBoundingBoxes, 'Mouth');
    imshow(IMouth)
    
    subplot(212);
    %     IFaces = insertMarker(I, [mouth_left_corner; mouth_right_corner; ...
    %         mouth_center_top_lip; mouth_center_bottom_lip]);
    
    IFaces = insertMarker(I, mouth_left_corner, 'o', 'Color', 'green', 'Size', 2);
    IFaces = insertMarker(IFaces, mouth_right_corner, 'x', 'Color', 'green', 'Size', 2);
    IFaces = insertMarker(IFaces, mouth_center_top_lip, '+', 'Color', 'green', 'Size', 2);
    IFaces = insertMarker(IFaces, mouth_center_bottom_lip, 's', 'Color', 'green', 'Size', 2);
    imshow(IFaces);
    
    
    while 1
        waitforbuttonpress;
        key = get(figure(1),'CurrentCharacter');
        if key == 's'
            fprintf('image = %s OUTLIER\n', positiveData(outlier_idx(i)).imageFilename);
            break;
            
        elseif key == 'n'
            break;
            
        else
            display('Press s to be outlier, n otherwise');
        end 
    end
    
end




