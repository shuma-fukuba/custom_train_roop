function Y = modelPredictions(net, mbq, classes)
    Y = [];
    while hasdata(mbq)
        X = next(mbq);
        scores = predict(net, X);
        labels = onehotdecode(scores, classes, 1)';
        Y = [Y; labels];
    end
end