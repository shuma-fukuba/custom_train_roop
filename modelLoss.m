function [loss, gradients, state] = modelLoss(net, X, T)
    % Forward
    [Y, state] = forward(net, X);
    loss = crossentropy(Y, T);
    gradients = dlgradient(loss, net.Learnables);
end