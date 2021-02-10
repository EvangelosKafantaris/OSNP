function [outputSignal] = outlierVarSegGen(inputSignal,signalLength,absoldev, percentage, groupsize, minmaxmode, outlierpercentage, posnegpercentage,sDev)

% 1) inputSignal: The input signal to be disrupted with outliers
% 2) signalLength: Actual length of input signal discarding potential NaN padding
% 3) absoldev: Absolue max deviation in signal
% 4) pecentage: Percentage of values to be disrupted
% 5) groupsize: number of disrupted samples grouped together

% 6) minmaxmode: possible inputs 1 or 0, enable using 1 as input when we want
% the starting value of outliers to be equal to that of the max value of
% the input signal

% 7) outlierpercentage: Amount of amplitude percentage increase occuring at
% outlier samples. If minmaxmode is activated the percentage increase is
% applied on top of the max value 

% 8) posnegpercentage: Percentage of positive versus negative outliers. The
% value declares the number of positive outliers and the rest are set to
% negative.

% 9) sdev: Standard deviation multiplier. This is applied on top of the max
% value to create a distribution of outliers

% We calculate the numGroups by flooring - ignoring the last set of samples
% that are not big enough to form a group because the last samples that
% are not enough to complete a group segment, will be ignored

% Ref:
% E. Kafantaris, I. Piper, T.Y.M Lo, J. Escudero:
% Assessment of Outliers and Detection of Artifactual Network Segments using 
% Univariate and Multivariate Dispersion Entropy on Physiological Signals,
% Entropy, 2021

% If you use the code, please make sure that you cite the above reference.

% Input parameter values used in the respective study:

% 1) inputSignal: Signal segment to be disrupted with outliers
% 2) signalLength: 7500
% 3) absoldev: Absolute maximum amplitude observed in the entire signal record
% 4) percentage: P factor value based on setup, range: 0.1%, 0.5%, 1%, 5%
% 5) groupsize: 1
% 6) minmaxmode: 1
% 7) outlierpercentage: 200 and 400
% 8) posnegpercentage: 50
% 9) sdev: 1


% Evangelos Kafantaris and Javier Escudero Rodriguez
% evangelos.kafantaris@ed.ac.uk and javier.escudero@ed.ac.uk
% 9-February-2021

%% (1) Setup
% Calculate number of total groups in signal
numGroups = floor(signalLength / groupsize);

driftdev = mean(abs(inputSignal));

% Initialise matrix that will store signal segments
choppedSignal = NaN(groupsize, numGroups);

% Allocate input signal to the matrix
for i = 1:numGroups
    choppedSignal(1:groupsize,i) = inputSignal(((i-1)*groupsize)+1:(i*groupsize));
end

numOutlierGroups = round(numGroups * percentage/100);

%% (2) Disruption

% Generate array that contains number of groups to be missing we use
% numGroups-1 to ensure that when we locate the samples at the actual
% signal we do not exceed its limits

missingOutlierLoc = randsample(numGroups-1,numOutlierGroups);

% Define which of these are on the positive max p
maxOutlierLoc = randsample(missingOutlierLoc, round(...
    (posnegpercentage * length(missingOutlierLoc)) /100));

% Produce outliers
for i = 1:numOutlierGroups
    
    % Minmax mode
    if minmaxmode == 1
        
        % Max Value
        if ismember(missingOutlierLoc(i),maxOutlierLoc)
        choppedSignal(:,missingOutlierLoc(i)) = absoldev .* normrnd((outlierpercentage/100),sDev);
        % Min Value
        else 
            choppedSignal(:,missingOutlierLoc(i)) = - absoldev .* normrnd((outlierpercentage/100),sDev);
        end
        
    % Relative to sample value
    else
        
        % Positive amplification
        if ismember(missingOutlierLoc(i),maxOutlierLoc)          
            choppedSignal(:,missingOutlierLoc(i)) = choppedSignal(:,missingOutlierLoc(i))...
                + driftdev .* (outlierpercentage/100);
        
        % Negative amplification
        else
            choppedSignal(:,missingOutlierLoc(i)) = choppedSignal(:,missingOutlierLoc(i))...
                - driftdev .* (outlierpercentage/100);
    
        end
    end 
    
end

%% (3) Output Check
outputSignal = reshape(choppedSignal,1,[]);

% Retrieve values of input signal that were ignored during disruption
% process. This requires two steps: (1) addition of final values
% and (2) replacing of any NaN values located in the outputSignal with values
% from the inputSignal

% Calculate difference in lengths

% dif = length(inputSignal)-length(outputSignal);


    outputSignal = [outputSignal,...
        inputSignal(length(outputSignal)+1:length(inputSignal))];

% Check the output signal to ensure it has no NaN values within its length
% If it does then feed in value from the input signal
for i = 1:length(outputSignal)
    if isnan(outputSignal(i))
        outputSignal(i) = inputSignal(i);
    end
end    
    
