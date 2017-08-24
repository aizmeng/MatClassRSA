 function [CM, accuracy, pVal, classifierInfo] = classifyEEG(X, Y, varargin)
% [CM, accuracy, classifierInfo] = classifyEEG(X, Y, shuffleData)
% -------------------------------------------------------------
% Blair/Bernard - Feb. 22, 2017
%
% The main function for sorting user inputs and calling classifier.
%
% INPUT ARGS (REQUIRED)
%   X - training data
%   Y - labels
%
% INPUT ARGS (OPTIONAL NAME-VALUE PAIRS)
%   normalize - method to normalize rows of X, 
%       --options--
%       'diagonal' (default)
%       'sum'
%       'none'
%   shuffleData - 1 to shuffle trainig data along with labels (default), or
%       --options--
%       1 - shuffle (default)
%       0 - do not shuffle
%   averageTrials - how to compute averaging of trials in X to increase accuracy
%       --options--
%       (negative value) - don't average
%       (postitive int) - number of integers to average over
%   permutationTest - TODO
%       --options--
%       TODO
%   PCA - Principle Component analysis on data matrix X. Default is to
%       keep components that explan 90% of the variance. To retrieve
%       components that explain a certain variance, enter the variance as a
%       decimal <1 and >0.  To retrieve a certain number of most
%       significant features, enter an integer >1.
%   PCAinFold - whether or not to conduct PCA in each fold
%       --options--
%       1 (default) - PCA within each fold
%       0 - one PCA for entire training data matrix X
%   nFolds - number of folds in cross validation.  Must be integer
%       greater than 1. Default is 10.
%   classify - parameter to select classifier. 
%        --options--
%       'SVM' (default)
%       'LDA' 
%       'RandomForest'
%   classifyOptionStruct - This is an option vector specific to each classifier
%       that comes in the form of a struct containing name-value pairs.
%       Acceptable name-value pairs are dependent on which classifier is
%       chosen for the 'classify' parameter in the main function.  
%       classifier: LDA
%           name: 'DiscrimType'
%           value: {'linear', 'quadratic', 'diagLinear', ... 
%                           'diagQuadratic', 'pseudoLinear', 'pseudoLinear'} 
%       classifier: SVM
%           name: 'kernel'
%           value: {'linear', 'polynomial', 'rbf', 'sigmoid'}
%       classifier: RF
%           name: 'numTrees'
%           value: *some positive integer*
%       pValueMethod: 
%       
% TODO:
%   Check when the folds = 1, what we should do 

    % convert Y to vector if its a cell array

    % Make sure input vector Y is int vector, convert if it is string
    % vector, string cell array, char vectors  

     addpath([pwd '/src/Classification/libsvm-3.21/matlab']);



    % Initialize the input parser
    ip = inputParser;
    ip.CaseSensitive = false;

    % ADD SPACEUSE TIMEUSE AND FEATUREUSE, DEAFULT SHOULD B EMPTY MATRIX
    
    %Specify default values
    defaultNormalize = 'diagonal';
    defaultShuffleData = 1;
    defaultAverageTrials = -1;
    defaultAverageTrialsHandleRemainder = 'discard';
    defaultPermutationTest = 0;
    defaultPCA = -1;
    defaultPCAinFold = 1;
    defaultNFolds = 10;
    defaultClassify = 'SVM';
    defaultClassifyOptionsStruct = struct([]);
    defaultPValueMethod = 'binomcdf';
    defaultPermutations = 0;
    defaultTimeUse = [];
    defaultSpaceUse = [];
    defaultFeatureUse = [];


    %Specify expected values
    expectedNormalize = {'diagonal', 'sum', 'none'};
    expectedShuffleData = [0, 1];
    expectedAverageTrialsHandleRemainder = {'discard','newGroup', 'append', 'distribute'};
    expectedPermutationTest = 0;
    expectedPCAinFold = [0,1];
    expectedClassify = {'SVM', 'LDA', 'RandomForest'};
    expectedPValueMethod = {'binomcdf', 'permuteLabels', 'permuteModel'};
    
    %Required inputs
    addRequired(ip, 'X', @is2Dor3DMatrix)
    addRequired(ip, 'Y', @isvector)
    [r c] = size(X);

    %Optional positional inputs
    %addOptional(ip, 'distpower', defaultDistpower, @isnumeric);
    if verLessThan('matlab', '8.2')
        addParamValue(ip, 'normalize', defaultNormalize,...
            @(x) any(validatestring(x, expectedNormalize)));
        addParamValue(ip, 'shuffleData', defaultShuffleData, ...
            @(x) (x==1 || x==0));
        addParamValue(ip, 'averageTrials', defaultAverageTrials, ...
            @(x) assert(rem(x,1) == 0 ));
        addParamValue(ip, 'averageTrialsHandleRemainder', ...
            defaultAverageTrialsHandleRemainder, ...
            @(x) assert(validatestring(x, expectedAverageTrialsHandleRemainder)));
        addParamValue(ip, 'permutationTest', defaultPermutationTest, ...
             @(x) any(validatestring(x, expectedPermutationTest)));
        addParamValue(ip, 'PCA', defaultPCA);
        addParamValue(ip, 'PCAinFold', defaultPCAinFold);
        addParamValue(ip, 'nFolds', defaultNFolds);
        addParamValue(ip, 'classify', defaultClassify, ...
             @(x) any(validatestring(x, expectedClassify)));
        addParamValue(ip, 'classifyOptionsStruct', defaultClassifyOptionsStruct, ...
            @(x) assert(isstruct(x)));
        addParamValue(ip, 'pValueMethod', defaultPValueMethod, ...
            @(x) any(validatestring(x, expectedPValueMethod)));
        % must be a positive integer
        addParamValue(ip, 'permutations', defaultPermutations, ...
            @(x) (x>0 && rem(x,1) == 0));
        addParamValue(ip, 'timeUse', defaultTimeUse, ...
            @(x) (assert(isvector(x))));
        addParamValue(ip, 'spaceUse', defaultSpaceUse, ...
            @(x) (assert(isvector(x))));
        addParamValue(ip, 'featureUse', defaultFeatureUse, ...
            @(x) (assert(isvector(x))));
    else
        addParameter(ip, 'normalize', defaultNormalize,...
            @(x) any(validatestring(x, expectedNormalize)));
        addParameter(ip, 'shuffleData', defaultShuffleData, ...
            @(x)  (x==1 || x==0));
        addParameter(ip, 'averageTrials', defaultAverageTrials, ...
            @(x) assert(rem(x,1) == 0 ));
        addParameter(ip, 'averageTrialsHandleRemainder', ...
            defaultAverageTrialsHandleRemainder, ...
            @(x) assert(validatestring(x, expectedAverageTrialsHandleRemainder)));
        addParameter(ip, 'permutationTest', defaultPermutationTest, ...
             @(x) any(validatestring(x, expectedPermutationTest)));
        addParameter(ip, 'PCA', defaultPCA);
        addParameter(ip, 'PCAinFold', defaultPCAinFold);
        addParameter(ip, 'nFolds', defaultNFolds);
        addParameter(ip, 'classify', defaultClassify, ...
             @(x) any(validatestring(x, expectedClassify)));
        addParameter(ip, 'classifyOptionsStruct', defaultClassifyOptionsStruct, ...
            @(x) assert(isstruct(x)));
        addParameter(ip,'pValueMethod', defaultPValueMethod, ...
             @(x) any(validatestring(x, expectedPValueMethod)));
        % must be a positive integer
        addParameter(ip, 'permutations', defaultPermutations, ...
            @(x) (x>0 && rem(x,1) == 0));
        addParameter(ip, 'timeUse', defaultTimeUse, ...
            @(x) (assert(isvector(x))));
        addParameter(ip, 'spaceUse', defaultSpaceUse, ...
            @(x) (assert(isvector(x))));
        addParameter(ip, 'featureUse', defaultFeatureUse, ...
            @(x) (assert(isvector(x))));
    end
    
    %Optional name-value pairs
    %NOTE: Should use addParameter for R2013b and later.


    % Parse
    parse(ip, X, Y, varargin{:});
    
    
    % Initilize info struct
    classifierInfo = struct('normalize', ip.Results.normalize, ...
                        'shuffleData', ip.Results.shuffleData, ...
                        'averageTrials', ip.Results.averageTrials, ...
                        'averageTrialsHandleRemainder', ip.Results.averageTrialsHandleRemainder,...
                        'permutationTest', ip.Results.permutationTest, ...
                        'PCA', ip.Results.PCA, ...
                        'PCAinFold', ip.Results.PCAinFold, ...
                        'nFolds', ip.Results.nFolds, ...
                        'classify', ip.Results.classify, ...
                        'classifyOptionsStruct', ip.Results.classifyOptionsStruct, ...
                        'pValueMethod', ip.Results.pValueMethod, ...
                        'permutations', ip.Results.permutations);
    

    %%%%% INPUT DATA CHECKING (doing)
    %%% Check the input data matrix X
    if ndims(X) == 3
        [nSpace, nTime, nTrials] = size(X);
        disp(['Input data matrix size: ' num2str(nSpace) ' space x ' ...
            num2str(nTime) ' time x ' num2str(nTrials) ' trials'])
    elseif ndims(X) == 2
        [nTrials, nFeature] = size(X);
        warning(['2D input data matrix. Assuming '...
            num2str(nTrials) ' trials x ' num2str(nFeature) ' features.'])
    else
        error('Input data matrix should be 3D or 2D matrix.')
    end
    %%% Check the input labels vector Y
    if ~isvector(Y)
        error('Input labels vector must be a vector.')
    elseif length(Y) ~= nTrials
        error(['Length of input labels vector must correspond '...
            'to number of trials (' num2str(nTrials) ').'])
    end
    % Convert to column vector if needed
    if ~iscolumn(Y)
       warning('Transposing input labels vector to column.') 
       Y = Y(:);
    end

    %%%%% INPUT DATA SUBSETTING (doing)
    % Default chanUse, timeUse, featureUse = [ ]
    spaceUse = ip.Results.spaceUse;
    timeUse = ip.Results.timeUse;
    featureUse = ip.Results.featureUse;
    
    %%% 3D input matrix
    X_subset = X; % This will be the next output; currently 3D or 2D
    if ndims(X) == 3
        % Message about ignoring 'featureUse' input
       if ~isempty(ip.Results.featureUse)
           warning('Ignoring ''featureUse'' for 3D input data matrix.')
           warning('Use ''spaceUse'' and ''timeUse'' for 3D input data matrix.')
       end

       % If the user did specify a spatial or temporal subset...
       if ~isempty(spaceUse) || ~isempty(timeUse)
           % Confirm that spaceUse and timeUse are vectors
           if (~isempty(spaceUse) && ~isvector(spaceUse)) ||...
                   (~isempty(timeUse) && ~isvector(timeUse))
               error('Enter a vector to specify spatial and/or temporal subsets.')
           end

           % Confirm that spaceUse and timeUse fit dimensions of data matrix
           if ~isempty(spaceUse) && ~all(ismember(spaceUse, 1:nSpace))
               error('''spaceUse'' input is not contained in the input data matrix.')
           elseif ~isempty(timeUse) && ~all(ismember(timeUse, 1:nTime))
               error('''timeUse'' input is not contained in the input data matrix.')
           end

           % Do the subsetting
           if ~isempty(spaceUse)
               X_subset = X_subset(spaceUse, :, :);
           end
           if ~isempty(timeUse)
               X_subset = X_subset(:, timeUse, :);
           end

           % Update nSpace and nTime
           nSpace = size(X_subset, 1);
           nTime = size(X_subset, 2);
       end
       % Reshape the X_subset matrix
       X_subset = cube2trRows(X_subset); % NOW IT'S 2D

    %%% 2D input matrix
    elseif ndims(X) == 2
        % Messages about ignoring 'spaceUse' and/or 'timeUse' inputs
        if ~isempty(spaceUse) || ~isempty(timeUse)
           if ~isempty(spaceUse)
               warning('Ignoring ''spaceUse'' for 2D input data matrix.')
           end
           if ~isempty(timeUse)
               warning('Ignoring ''timeUse'' for 2D input data matrix.')
           end
           warning('Use ''featureUse'' for 2D input data matrix.')
        end

        % If the user specified a featureUse subset...
        if ~isempty(featureUse)
            % Confirm it's a vector
            if ~isvector(featureUse)
               error('Enter a vector to specify feature subsets.') 
            end

           % Confirm that featureUse is contained in the data matrix
           if ~all(ismember(featureUse, 1:nFeature))
              error('''featureUse'' input is not contained in the input data matrix.') 
           end

           % Do the subsetting
           X_subset = X_subset(:, featureUse);  % WAS ALREADY 2D

           % Update nFeature
           nFeature = size(X_subset, 2);
        end  
    end
    X = X_subset;
    % let r and c store size of 2D matrix
    [r c] = size(X);
    
    %%%%% Whatever we started with, we now have a 2D trials-by-feature matrix
    % moving forward.

    % DATA SHUFFLING (doing)
    % Default 1
    if (ip.Results.shuffleData)
        [X, Y] = shuffleData(X, Y);
    else
        classifierInfo.shuffleData = 'off';
    end

    % TRIAL AVERAGING (doing)
     if(ip.Results.averageTrials >= 1)
        [X, Y] = averageTrials(X, Y, ip.Results.averageTrials, ...
            'handleRemainder' ,ip.Results.averageTrialsHandleRemainder);
        averageTrialsInfo = 'on';
        classifierInfo.averageTrials = 'on';
     else
         warning('variable "defaultAverageTrialsHandleRemainder" not used')
     end

    % Split Data into fold (w/ or w/o PCA)
    partition = cvpart(r, ip.Results.nFolds);
    tic
    cvDataObj = cvData(X,Y, partition,ip.Results.PCA, ip.Results.PCAinFold);
    toc
    
    
    %PERMUTATION TEST (assigning)
    [r c] = size(X);
    tic
    switch ip.Results.pValueMethod
        case 'binomcdf'
            % case is handled at the end, when the accuracy of the
            % classifier is calculated
        case 'permuteLabels'
            [funcOutput accDist] = evalc( ['permuteLabels(Y, cvDataObj, ip.Results.nFolds,'   ...
                'ip.Results.permutations, ip.Results.classify,' ...
                'ip.Results.classifyOptionsStruct )'] );
        case 'permuteModel'
            [funcOutput accDist] = evalc( ['permuteModel(cvDataObj, ip.Results.nFolds,' ...
                'ip.Results.permutations, ip.Results.classify,' ...
                'ip.Results.classifyOptionsStruct )'] );
        case 'None'
    end
    toc
    
    disp('AYYYYYE TOCCED');
    
    

    % Just partition, as shuffling (or not) was handled in previous step
    % if nFolds == 1
    if ip.Results.nFolds == 1
        % Special case of fitting model with no test set (argh)
        error('nFolds must be a integer value greater than 1');
    end

    % if nFolds < 0 | ceil(nFolds) ~= floor(nFolds) | nFolds > nTrials
    %   error, nFolds must be an integer between 2 and nTrials to perform CV
    assert(ip.Results.nFolds > 0 & ...
        ceil(ip.Results.nFolds) == floor(ip.Results.nFolds) & ...
        ip.Results.nFolds < nTrials, ...
        'nFolds must be an integer between 2 and nTrials to perform CV' );
        
        predictionsConcat = [];
        labelsConcat = [];
        
%         pVal = permuteLabels(X, Y, cvDataObj, ip.Results.nFolds, ...
%             ip.Results.permutations, ip.Results.classify, ...
%             ip.Results.classifyOptionsStruct );

    for i = 1:ip.Results.nFolds

%         trainX = bsxfun(@times, partition.training{i}, X);
%         trainX = trainX(any(trainX~=0,2),:);
%         trainY = bsxfun(@times, partition.training{i}', Y);
%         trainY = trainY(trainY ~=0);
%         testX = bsxfun(@times, partition.test{i}, X);
%         testX = testX(any(testX~=0, 2),:);
%         testY = bsxfun(@times, partition.test{i}', Y);
%         testY = testY(testY ~=0);
        
        % data for permutation testing
        % seems like we don't need
%         pTrainY = bsxfun(@times, partition.training{i}', pY);
%         pTrainY = pTrainY(pTrainY ~=0);
%         pTestY = bsxfun(@times, partition.test{i}', pY);
%         pTestY = pTestY(pTestY ~=0);
%         pPredictedY = NaN(1, length(pTestY));

%         if (ip.Results.PCAinFold == 1)
%             if (ip.Results.PCA > 0)
%                 [trainX, V, nPC] = getPCs(trainX, ip.Results.PCA);
%                 testX = testX*V;
%                 testX = testX(:,1:nPC);
%             end
%         end

        trainX = cvDataObj.trainXall{i};
        trainY = cvDataObj.trainYall{i};
        testX = cvDataObj.trainXall{i};
        testY = cvDataObj.trainYall{i};

            [funcOutput mdl] = evalc(['fitModel(trainX, trainY, ip.Results.classify,' ...
                'ip.Results.classifyOptionsStruct)']);
            predictions = modelPredict(testX, mdl);
        
        labelsConcat = [labelsConcat testY];
        predictionsConcat = [predictionsConcat predictions];
        
        
        %predictcedY(partition.test(i)) = predictions;
    end
    CM = confusionmat(labelsConcat, predictionsConcat);
    accuracy = computeAccuracy(labelsConcat, predictionsConcat); 
    
    switch ip.Results.pValueMethod
        case 'binomcdf'
            pVal = pbinom(Y, ip.Results.nFolds, accuracy);
        case 'permuteLabels'
            pVal = permTestPVal(accuracy, accDist);
        case 'permuteModel'
            pVal = permTestPVal(accuracy, accDist);
        case 'None'
    end
    
 end

 
 function y = is2Dor3DMatrix(x)
 
    if ismatrix(x)
        y = 1;
    elseif isequal(size(size(x)), [1 3])
        y = 1;
    else
        y=0;
    end
 end
    