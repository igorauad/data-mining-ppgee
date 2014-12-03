%% Initialize
load('data/training.mat')
posCollectionPath = 'img/positives/';

%% Load detector
detector_choice = 'Matlab';

switch detector_choice
    case 'Matlab'
        detector = vision.CascadeObjectDetector('Mouth');
    case 'Ours'
        detector = vision.CascadeObjectDetector('mouthDetector.xml');
end

%% Average of the bounding boxes

nImages = length(training);

for i = 1
    
end
    

%% Bouding Boxes
iImage = 6;

filename = [posCollectionPath, 'img', num2str(iImage, '%1.4d'), '.png'];
I = imread(filename);
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
box_width = sqrt(sum(abs(mouth_left_corner - mouth_right_corner).^2));
box_height = sqrt(sum(abs(mouth_center_top_lip - mouth_center_bottom_lip).^2));

real_box = [topLeftCornerX, ...
    topLeftCornerY, ...
    box_width, box_height];

detected_box = step(detector, I);
[box_y_max, iBoxMaxY] = max(detected_box(:,2))

IFaces = insertObjectAnnotation(I, 'rectangle', [real_box; detected_box(iBoxMaxY, :)], ...
    'Mouth', 'color', {'red', 'green'});
imshow(IFaces);
% Red -> real
% Green -> Estimated
