%% Filenames:
trainFile = 'data/training.csv'
testFile = 'data/test.csv'

%% Process Training Data
trainingData = csvimport(trainFile);  

% Remove images from trainingData:
trainingImages = trainingData(:, 31);
trainingData = trainingData(:, 1:30);

% Fields, other than the "Image" field 
fields = trainingData(1, 1:end);

% Remove header:
trainingData = trainingData(2:end, :);
trainingImages = trainingImages(2:end, :);

nImages = length(trainingData);  

% Put data and images in struct:
for k = 1:length(fields)
    
    % Original column:
    originalTrainingColumn = trainingData(:,k);
    
    % Test if it is already numeric:
    if (isnumeric(originalTrainingColumn{1}))
        trainingColumn = originalTrainingColumn;
    else
        trainingColumn = cellfun(@str2num, trainingData(:,k), ...
            'UniformOutput', false);
    end
    
    % Check if dimensions are ok
    if (size(trainingColumn, 1) ~= nImages)
       warning('Inconsistent size at the column'); 
    end
    
    % Process Missing Values
    ix = cellfun(@isempty,trainingColumn); % Indexes of NA's
    trainingColumn(ix) = {nan};            % set as NaN
    
    % Convert to numeric:
    numericColumn = cell2mat(trainingColumn);
    
    % Check again if dimensions are ok
    if (size(numericColumn, 1) ~= nImages)
       warning('Inconsistent size at the column'); 
    end
    
    % Set values in struct array:
    for i = 1:nImages
        training(i).(fields{k}) = numericColumn(i);
    end
end

for i = 1:nImages
    % Image as Char vector:
    imgStrVector = trainingImages(i);
    % Convert to Int vector:
    imgIntVector = str2num(imgStrVector{1}); %#ok<ST2NM>
    % Reshape to 96 x 96 image:
    training(i).Image = reshape(imgIntVector, 96, 96).';
end

save('training', 'training')

clear trainingData training

%% Process Test data
testData = csvimport(testFile);

% Remove header:
testData = testData(2:end, :);

nImages = length(testData);  

ImageIdColumn = testData(:, 1);

for i = 1:nImages
    % Image as Char vector:
    imgStrVector = testData(i, 2);
    % Convert to Int vector:
    imgIntVector = str2num(imgStrVector{1}); %#ok<ST2NM>
    % Set ImageId
    test(i).ImageId = ImageIdColumn{i};
    % Reshape to 96 x 96 image:
    test(i).Image = reshape(imgIntVector, 96, 96).';
end

% Put data and images in struct:
save('test', 'test')

