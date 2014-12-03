%% Training images
load('data/training.mat')

nTraining = length(training);

path = 'img/positives/';

for iImage = 1:nTraining
    I = training(iImage).Image / 255;
    filename = [path, 'img', num2str(iImage, '%1.4d'), '.png'];
    imwrite(I, filename)
end

%% Test Images