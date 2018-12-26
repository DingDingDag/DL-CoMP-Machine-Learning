% http://www.mathworks.com/help/stats/support-vector-machines-svm.html
function [error, SVMModel] = SVM(x1,x2,x3,is_dnn)
global epsilon;

rng(0);

%newX has the format [CQI, RSRP]
X = [x1,x2];
Y = (x3 <= 0.1);  % Did BLER target fulfillment succeed?

split = 0.7;
 
% Split 
X_training = X(1:round(length(X)*split),:);
Y_training = Y(1:round(length(Y)*split),:);
X_test = X(round(length(X)*split)+1:end,:);
Y_test = Y(round(length(Y)*split)+1:end,:);

X_training = X;
Y_training = Y;

%figure, histogram(Y_training, 'BinWidth', 0.2)
%grid on

% Perform SMOTE - K = 5
%[X_training, Y_training] = ADASYN(X_training, Y_training);

%xlabel('Label')
%ylabel('Count')
%title('Classification Balance - Prior')

%  'KernelFunction', 'rbf', ... %rbf linear gaussian polynomial
try
    if (is_dnn)
        % This is DNN-like
        SVMModel = fitcsvm(X_training, Y_training, ...
            'ClassNames',[0 1], ...
            'Standardize', true, ...
            'KernelFunction', 'mysigmoid');
    else 
        % This is SVM
        SVMModel = fitcsvm(X_training, Y_training, ...
            'ClassNames',[0 1], ...
            'Standardize', true, ...
            'OptimizeHyperparameters','all', ...
            'HyperparameterOptimizationOptions',struct('MaxObjectiveEvaluations', 5, ...
                'ShowPlots', false)); 
    end

    % Perform K-Fold Cross Validation
    %CVSVMModel = crossval(SVMModel, 'Kfold', 3);
    % error = 1 - mean(kfoldPredict(CVSVMModel) == Y_training);  % very strange from MATLAB!
    
    % Test error
    Y_hat = predict(SVMModel, X_test);
    error = 1 - mean(Y_hat == Y_test);

    fprintf('CoMP Cluster: Classification error is %0.1f%%.\n', error * 100);

    if error > epsilon
        SVMModel = [];
        fprintf('CoMP Cluster: SVM error is too high.  Using operator setting.\n');
        return
    end
catch ME 
    error = 1;
    fprintf('CoMP Cluster: Classification cannot be obtained.  Skipped.\n');
    SVMModel = [];
end


