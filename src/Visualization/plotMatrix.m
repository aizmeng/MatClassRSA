function img = plotMatrix(RDM, varargin)
%-------------------------------------------------------------------
% plotMatrix(matrix, varargin)
% ------------------------------------------------
% Bernard Wang - April 23, 2017
%
% This function plots a confusion matrix with the
% specified labels.
%
% INPUT ARGS:
% - matrix: A matrix, e.g. a confusion matrix or a distance matrix
%
% Optional name-value pairs:
%   'axisColors': a vector of colors, ordered by the order of labels in the 
%       confusion matrix e.g. {?y? ?m? ?c? ?r?} or {?yellow? ?magenta? ?cyan? ?red?}
%       or {?[1 1 0]? ?[1 0 1]? ?[0 1 1]? ?[1 0 0]?}
%   'axisLabels': a matrix of alphanumeric labels, ordered by same order of
%       labels in the confusion matrix e.g. ['cat' 'dog' 'fish']
%   'iconPath': a directory containing images used to label, in which the
%       image files must be ordered in the same order as the labels of the 
%       confusion matrix
%   ?colorMap? - This parameter can be used to call a default Matlab colormap, 
%       or one specified by the user, to change the overall look of the plot. 
%   For example, plotMatrix(RDM, ?colorMap?, ?hsv?)
%       ?colorBar? - Choose whether to display colorbar or not (default 0)
%       --options--
%       0 - hide (default)
%       1 - show
%   ?matrixLabels? -  Use this parameter to choose whether or not to display 
%       values for each square in the matrix.  Ignore parameter to turn off, 
%       enter any value to turn on.
%   ?FontSize? - Set font size of matrix and axis labels. Default 15
%   'ticks' - Set number of ticks on the colorbar, Default 5
%   'textRotation' - Set rotation of text.  Default 0
%   'iconSize' - If 'iconPath' parameter is used, use this to set the size
%       of image labels. Default 40.
%   
%
% Notes:
%   6 types of labels for the visualiations:
%       Color labels
%       Character labels
%       Image labels
%       Color character labels
%       color image labels
%       None
%  
% TODO: test, calcuate optimal size for icons

% This software is licensed under the 3-Clause BSD License (New BSD License), 
% as follows:
% -------------------------------------------------------------------------
% Copyright 2017 Bernard C. Wang, Anthony M. Norcia, and Blair Kaneshiro
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% 1. Redistributions of source code must retain the above copyright notice, 
% this list of conditions and the following disclaimer.
% 
% 2. Redistributions in binary form must reproduce the above copyright notice, 
% this list of conditions and the following disclaimer in the documentation 
% and/or other materials provided with the distribution.
% 
% 3. Neither the name of the copyright holder nor the names of its 
% contributors may be used to endorse or promote products derived from this 
% software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ?AS IS?
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.

    % parse inputs
    ip = inputParser;
    ip.FunctionName = 'plotCM';
    ip.addRequired('matrix',@ismatrix);
    options = [1, 0];
    ip.addParameter('axisColors', [], @(x) isvector(x)); 
    ip.addParameter('axisLabels', [], @(x) isvector(x));
    ip.addParameter('iconPath', '');
    ip.addParameter('colormap', '');
    ip.addParameter('colorbar', '');
    ip.addParameter('matrixLabels', 1);
    ip.addParameter('FontSize', 15, @(x) isnumeric(x));
    ip.addParameter('ticks', 5, @(x) (isnumeric(x) && x>0));
    ip.addParameter('textRotation', 0, @(x) assert(isnumeric(x), ...
        'textRotation must be a numeric value'));
    ip.addParameter('iconSize', 40);
    parse(ip, RDM, varargin{:});
    
    imagesc(RDM);
    img = gcf;

    
    if ~isempty(ip.Results.colormap)
        colormap(ip.Results.colormap);
    end
    
    if (ip.Results.matrixLabels==1)
        % Label the dendrogram with values
        % 
        textStrings = num2str(RDM(:),'%0.2f');  %# Create strings from the matrix values
        textStrings = strtrim(cellstr(textStrings));  %# Remove any space padding
        [x,y] = meshgrid(1:length(RDM));   %# Create x and y coordinates for the strings
        text(x(:),y(:),textStrings(:),...      %# Plot the strings
                    'HorizontalAlignment','center', ...
                    'FontSize', ip.Results.FontSize);
    end
    
    if ip.Results.colorbar > 0
        c = colorbar;
        c.FontSize = ip.Results.FontSize;
        matMin = min(min(RDM));
        matMax = max(max(RDM));
        %truncMax = fix(matMax * 10^2)/10^2;
        inc = (matMax - matMin)/(ip.Results.ticks-1);
        c.Ticks = str2num(sprintf('%.2f2 ', [[0:ip.Results.ticks-2] * inc + matMin  matMax]));
        c.FontWeight = 'bold';
    end
    

    
    % check which set of labels to use
    % alphanumeric labels
    if ~isempty(ip.Results.axisLabels)
        labels = ip.Results.axisLabels;
    %picture labels
    elseif ~isempty(ip.Results.iconPath)
        labels = getImageFiles(ip.Results.iconPath);
    elseif isempty(ip.Results.axisLabels) && isempty(ip.Results.iconPath) && ~isempty(ip.Results.axisColors)
         labels = ip.Results.axisColors;
    else %no labels specified
%         set(gca,'xtick',[]);
%         set(gca,'ytick',[]);
        return;
    end
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CASE:  DEFAULT LABELS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if isempty(ip.Results.axisColors) && isempty(ip.Results.axisLabels) ...
            && isempty(ip.Results.iconPath)
    disp('CASE: DEAFULT LABELS')

   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CASE:  AXIS COLOR LABEL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif ~isempty(ip.Results.axisColors) && ~isempty(ip.Results.axisLabels) ...
            && isempty(ip.Results.iconPath)
        
        disp('CASE: AXIS COLOR LABELS')

        [xTickCoords yTickCoords] = getTickCoord;
        set(gca,'xTickLabel', '');
        set(gca,'yTickLabel', '');
        numLabels = length(labels);
        bottomYCoord =  numLabels + .5;

        
        for i = 1:length(labels)
                label = labels(i);
                t = text(xTickCoords(i, 1), bottomYCoord, label, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'top');
                t.Rotation = ip.Results.textRotation;
                t.Color = ip.Results.axisColors{i};
                t(1).FontSize = 25;
        end
        
        for i = 1:length(labels)
                label = labels(i);
                t = text(yTickCoords(i, 1), yTickCoords(i, 2), label, ...
                    'HorizontalAlignment', 'center');
                t.Rotation = ip.Results.textRotation;
                t.Color = ip.Results.axisColors{i};
                t(1).FontSize = 25;

        end
        

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CASE: AXIS LABEL
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif isempty(ip.Results.axisColors) && ~isempty(ip.Results.axisLabels) ...
            && isempty(ip.Results.iconPath)
        disp('CASE: LABEL')

        set(gca,'xTickLabel', '');
        set(gca,'yTickLabel', '');

        set(gca,'xTickLabel', ip.Results.axisLabels, 'FontSize', ip.Results.FontSize);
        set(gca,'yTickLabel', ip.Results.axisLabels, 'FontSize', ip.Results.FontSize);

        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % CASE: IMAGE
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif  ~isempty(ip.Results.iconPath) ...
            && isempty(ip.Results.axisLabels)
        
          
        set(gca,'xTick', [1:length(RDM)]);
        set(gca,'yTick',  [1:length(RDM)]);
        set(gca,'xTickLabel', '');
        set(gca,'yTickLabel', '');
        
        [xTickCoords yTickCoords] = getTickCoord;

        pos = get(gca,'position');
        leftMargin = pos(1);
        bottomMargin = pos(2);
        topMargin = pos(2) + pos(4);
        xdlta = (pos(3)) / (length(xTickCoords));
        ydlta = (pos(4)) / (length(yTickCoords));
        xinit = xdlta/2;
        yinit = ydlta/2;
        figPos = get(gcf, 'position');
        figWidth = figPos(3);
        figHeight = figPos(4);
        
        for i = 1:length(labels)
            [thisIcon map] = imread([char(labels(i))]);
            [height width] = size(thisIcon);
            %convert thisIcon to scale 0~1
            
            if ~isempty(map)
%               converting to RGB
                %disp(map);
                thisIcon = ind2rgb(thisIcon, map);

            end
            
            % Resize to 40*40 square
            if height > width
                thisIcon = imresize(thisIcon, [ip.Results.iconSize NaN]);
            else
                thisIcon = imresize(thisIcon, [NaN ip.Results.iconSize]);
            end

            % Add 3rd(color) dimension if there is none
            if length(size(thisIcon)) == 2
                thisIcon = cat(3, thisIcon, thisIcon, thisIcon);
            end

            if i <= length(labels)
                % plot x axis labels
                lblAx = axes('parent',gcf,'position', ...
                    [leftMargin + xinit + xdlta * (i-1) - ip.Results.iconSize/2/figWidth ...
                    ,bottomMargin-ip.Results.iconSize/figHeight, ...
                    ip.Results.iconSize/figWidth, ip.Results.iconSize/figHeight]);
                imagesc(thisIcon,'parent',lblAx);
                axis(lblAx,'off');
                % plot y axis labels
                lblAx = axes('parent',gcf,'position', ...
                    [leftMargin - ip.Results.iconSize/figWidth ...
                    ,topMargin - yinit - ydlta * (i-1) - ip.Results.iconSize/2/figHeight, ...
                    ip.Results.iconSize/figWidth, ip.Results.iconSize/figHeight]);
                imagesc(thisIcon,'parent',lblAx);
                axis(lblAx,'off');
            else
            end
        end
        
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % CASE: COLOR
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif ~isempty(ip.Results.axisColors) && isempty(ip.Results.iconPath) ...
            && isempty(ip.Results.axisLabels)
        
                
        
          
        set(gca,'xTick', [1:length(RDM)]);
        set(gca,'yTick',  [1:length(RDM)]);
        set(gca,'xTickLabel', '');
        set(gca,'yTickLabel', '');
        
        [xTickCoords yTickCoords] = getTickCoord;

        pos = get(gca,'position');
        leftMargin = pos(1);
        bottomMargin = pos(2);
        topMargin = pos(2) + pos(4);
        xdlta = (pos(3)) / (length(xTickCoords));
        ydlta = (pos(4)) / (length(yTickCoords));
        xinit = xdlta/2;
        yinit = ydlta/2;
        figPos = get(gcf, 'position');
        figWidth = figPos(3);
        figHeight = figPos(4);
        
        for i = 1:length(labels)
            
            % plot x axis labels
            lblAx = axes('parent',gcf,'position', ...
                [leftMargin + xinit + xdlta * (i-1) - ip.Results.iconSize/2/figWidth ...
                ,bottomMargin-ip.Results.iconSize/figHeight, ...
                ip.Results.iconSize/figWidth, ip.Results.iconSize/figHeight]);
            rectangle('FaceColor', labels{i});
            axis(lblAx,'off');
            % plot y axis labels
            lblAx = axes('parent',gcf,'position', ...
                [leftMargin - ip.Results.iconSize/figWidth ...
                ,topMargin - yinit - ydlta * (i-1) - ip.Results.iconSize/2/figHeight, ...
                ip.Results.iconSize/figWidth, ip.Results.iconSize/figHeight]);
            rectangle('FaceColor', labels{i});
            axis(lblAx,'off');

        end
        
    
    

end