imds = imageDatastore("DigitsData", ...
    IncludeSubfolders=true, ...
    LabelSource="foldernames");
[imdsTrain, imdsValidation] = splitEachLabel(imds, 0.9, "randomized");

inputSize = [28 28  1];
pixelRange = [-5 5];

imageAugmenter = imageDataAugmenter( ...
    RandXTranslation=pixelRange, ...
    RandYTranslation=pixelRange);
augimdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain, DataAUgmentation=imageAugmenter);  % データ拡張

augimdsValidation = augmentedImageDatastore(inputSize(1:2),imdsValidation);

classes = categories(imdsTrain.Labels);
numClasses = numel(classes);


layers = [
    imageInputLayer(inputSize, Normalization="none")
    convolution2dLayer(5, 20, Padding="same")
    batchNormalizationLayer
    reluLayer
    convolution2dLayer(3, 20, Padding="same")
    batchNormalizationLayer
    reluLayer
    convolution2dLayer(3, 20, Padding="same")
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(numClasses)
    softmaxLayer
    ];

net = dlnetwork(layers);

numEpochs = 10;
miniBatchSize = 128;

initialLearnRate = 0.01;
dcay = 0.01;
momentum = 0.9;

mbq = minibatchqueue(augimdsTrain,...
    MiniBatchSize=miniBatchSize,...
    MiniBatchFcn=@preprocessMiniBatch,...
    MiniBatchFormat=["SSCB" ""], ...
    PartialMiniBatch="discard");

velocity = [];

numObservationsTrain = numel(imdsTrain.Files);
numIterationsPerEpoch = floor(numObservationsTrain / miniBatchSize);
numIterations = numEpochs * numIterationsPerEpoch;

monitor = trainingProgressMonitor( ...
    Metrics="Loss", ...
    Info=["Epoch" "LearnRate"], ...
    XLabel="Iteration");

epoch = 0;
iteration = 0;

while epoch < numEpochs && ~monitor.Stop
    epoch = epoch + 1;
    shuffle(mbq);
    while hasdata(mbq) && ~monitor.Stop
        iteration = iteration + 1;
        [X, T] = next(mbq);

        [loss, gradients, state] = dlfeval(@modelLoss, net, X, T);
        net.State = state;
        learnRate = initialLearnRate / (1 + dcay * iteration);
        [net, velocity] = sgdmupdate(net, gradients, velocity, learnRate, momentum);

        recordMetrics(monitor, iteration, Loss=loss);
        updateInfo(monitor,Epoch=epoch,LearnRate=learnRate);
        monitor.Progress = 100 * iteration / numIterations;
    end
end


